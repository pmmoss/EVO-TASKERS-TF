#!/bin/bash
# EVO-TASKERS Deployment Validation Script
# This script validates that the infrastructure is deployed correctly

set -e

# Configuration
ENVIRONMENT="${1:-dev}"
STATE_RG="rg-evotaskers-state-pmoss"
STATE_ACCOUNT="stevotaskersstatepoc"
STATE_CONTAINER="tfstate"

echo "=========================================="
echo "EVO-TASKERS Deployment Validation"
echo "Environment: ${ENVIRONMENT}"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Get resource group name from common state
echo -e "\n1. Fetching Common Infrastructure State..."
COMMON_STATE_KEY="landing-zone/evo-taskers-common-${ENVIRONMENT}.tfstate"

# Check if common state exists
az storage blob show \
    --account-name "${STATE_ACCOUNT}" \
    --container-name "${STATE_CONTAINER}" \
    --name "${COMMON_STATE_KEY}" \
    --output none 2>/dev/null && check_pass "Common state file exists" || check_fail "Common state file not found"

# Get outputs from Terraform state (requires terraform installed)
if command -v terraform &> /dev/null; then
    cd common
    terraform init -backend=false &> /dev/null
    
    # Get resource group name
    RG_NAME=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    
    if [ -n "${RG_NAME}" ]; then
        check_pass "Retrieved resource group name: ${RG_NAME}"
    else
        check_warn "Could not retrieve resource group name from Terraform"
        RG_NAME="rg-evotaskers-${ENVIRONMENT}-eus"
        echo "   Using default: ${RG_NAME}"
    fi
    cd ..
else
    RG_NAME="rg-evotaskers-${ENVIRONMENT}-eus"
    check_warn "Terraform not found, using default RG name: ${RG_NAME}"
fi

# Verify Resource Group
echo -e "\n2. Checking Resource Group..."
if az group show --name "${RG_NAME}" --output none 2>/dev/null; then
    check_pass "Resource Group '${RG_NAME}' exists"
    
    # Get location
    LOCATION=$(az group show --name "${RG_NAME}" --query "location" -o tsv)
    echo "   Location: ${LOCATION}"
else
    check_fail "Resource Group '${RG_NAME}' not found"
    exit 1
fi

# Verify Virtual Network
echo -e "\n3. Checking Virtual Network..."
VNET_COUNT=$(az network vnet list --resource-group "${RG_NAME}" --query "length(@)" -o tsv)
if [ "${VNET_COUNT}" -gt 0 ]; then
    VNET_NAME=$(az network vnet list --resource-group "${RG_NAME}" --query "[0].name" -o tsv)
    check_pass "Virtual Network '${VNET_NAME}' exists"
    
    # Check subnets
    SUBNET_COUNT=$(az network vnet subnet list --resource-group "${RG_NAME}" --vnet-name "${VNET_NAME}" --query "length(@)" -o tsv)
    echo "   Subnets: ${SUBNET_COUNT}"
else
    check_fail "No Virtual Network found"
fi

# Verify Storage Account
echo -e "\n4. Checking Storage Account..."
STORAGE_COUNT=$(az storage account list --resource-group "${RG_NAME}" --query "length(@)" -o tsv)
if [ "${STORAGE_COUNT}" -gt 0 ]; then
    STORAGE_NAME=$(az storage account list --resource-group "${RG_NAME}" --query "[0].name" -o tsv)
    check_pass "Storage Account '${STORAGE_NAME}' exists"
else
    check_fail "No Storage Account found"
fi

# Verify Key Vault
echo -e "\n5. Checking Key Vault..."
KV_COUNT=$(az keyvault list --resource-group "${RG_NAME}" --query "length(@)" -o tsv)
if [ "${KV_COUNT}" -gt 0 ]; then
    KV_NAME=$(az keyvault list --resource-group "${RG_NAME}" --query "[0].name" -o tsv)
    check_pass "Key Vault '${KV_NAME}' exists"
else
    check_fail "No Key Vault found"
fi

# Check Shared State
echo -e "\n6. Checking Shared Services State..."
SHARED_STATE_KEY="shared/evo-taskers-shared-${ENVIRONMENT}.tfstate"

if az storage blob show \
    --account-name "${STATE_ACCOUNT}" \
    --container-name "${STATE_CONTAINER}" \
    --name "${SHARED_STATE_KEY}" \
    --output none 2>/dev/null; then
    check_pass "Shared state file exists"
else
    check_warn "Shared state file not found - shared services may not be deployed"
    echo "   Expected: ${SHARED_STATE_KEY}"
fi

# Verify App Service Plans
echo -e "\n7. Checking App Service Plans..."
PLAN_COUNT=$(az appservice plan list --resource-group "${RG_NAME}" --query "length(@)" -o tsv)

if [ "${PLAN_COUNT}" -gt 0 ]; then
    check_pass "Found ${PLAN_COUNT} App Service Plan(s)"
    
    echo -e "\n   App Service Plans:"
    az appservice plan list --resource-group "${RG_NAME}" \
        --query "[].{Name:name, SKU:sku.name, OS:kind, Apps:numberOfSites, Status:status}" \
        -o table | sed 's/^/   /'
    
    # Check for shared plans
    WINDOWS_PLAN_COUNT=$(az appservice plan list --resource-group "${RG_NAME}" \
        --query "[?contains(name, 'functions-windows')] | length(@)" -o tsv)
    
    LOGIC_PLAN_COUNT=$(az appservice plan list --resource-group "${RG_NAME}" \
        --query "[?contains(name, 'logicapps')] | length(@)" -o tsv)
    
    if [ "${WINDOWS_PLAN_COUNT}" -gt 0 ]; then
        WINDOWS_PLAN_NAME=$(az appservice plan list --resource-group "${RG_NAME}" \
            --query "[?contains(name, 'functions-windows')].name | [0]" -o tsv)
        WINDOWS_APP_COUNT=$(az appservice plan show --name "${WINDOWS_PLAN_NAME}" \
            --resource-group "${RG_NAME}" --query "numberOfSites" -o tsv)
        check_pass "Windows Function Plan: ${WINDOWS_APP_COUNT} app(s)"
    else
        check_warn "Shared Windows Function Plan not found"
    fi
    
    if [ "${LOGIC_PLAN_COUNT}" -gt 0 ]; then
        LOGIC_PLAN_NAME=$(az appservice plan list --resource-group "${RG_NAME}" \
            --query "[?contains(name, 'logicapps')].name | [0]" -o tsv)
        LOGIC_APP_COUNT=$(az appservice plan show --name "${LOGIC_PLAN_NAME}" \
            --resource-group "${RG_NAME}" --query "numberOfSites" -o tsv)
        check_pass "Logic App Plan: ${LOGIC_APP_COUNT} app(s)"
    else
        check_warn "Shared Logic App Plan not found"
    fi
else
    check_warn "No App Service Plans found - shared services may not be deployed"
fi

# Verify Function Apps
echo -e "\n8. Checking Function Apps..."
FUNC_COUNT=$(az functionapp list --resource-group "${RG_NAME}" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "${FUNC_COUNT}" -gt 0 ]; then
    check_pass "Found ${FUNC_COUNT} Function App(s)"
    
    echo -e "\n   Function Apps:"
    az functionapp list --resource-group "${RG_NAME}" \
        --query "[].{Name:name, State:state, Runtime:kind}" \
        -o table | sed 's/^/   /'
    
    # Check if they're using shared plans
    echo -e "\n   Checking which plans Function Apps are using..."
    for FUNC_NAME in $(az functionapp list --resource-group "${RG_NAME}" --query "[].name" -o tsv); do
        PLAN_ID=$(az functionapp show --name "${FUNC_NAME}" --resource-group "${RG_NAME}" \
            --query "serverFarmId" -o tsv)
        PLAN_NAME=$(basename "${PLAN_ID}")
        
        if [[ "${PLAN_NAME}" == *"functions-windows"* ]]; then
            check_pass "${FUNC_NAME} → using shared plan"
        else
            check_warn "${FUNC_NAME} → using individual plan '${PLAN_NAME}'"
        fi
    done
else
    check_warn "No Function Apps found"
fi

# Verify Logic Apps
echo -e "\n9. Checking Logic Apps..."
LOGIC_COUNT=$(az logicapp list --resource-group "${RG_NAME}" --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "${LOGIC_COUNT}" -gt 0 ]; then
    check_pass "Found ${LOGIC_COUNT} Logic App(s)"
    
    echo -e "\n   Logic Apps:"
    az logicapp list --resource-group "${RG_NAME}" \
        --query "[].{Name:name, State:state, Kind:kind}" \
        -o table | sed 's/^/   /'
    
    # Check if they're using shared plans
    echo -e "\n   Checking which plans Logic Apps are using..."
    for LOGIC_NAME in $(az logicapp list --resource-group "${RG_NAME}" --query "[].name" -o tsv); do
        PLAN_ID=$(az logicapp show --name "${LOGIC_NAME}" --resource-group "${RG_NAME}" \
            --query "appServicePlanId" -o tsv)
        PLAN_NAME=$(basename "${PLAN_ID}")
        
        if [[ "${PLAN_NAME}" == *"logicapps"* ]]; then
            check_pass "${LOGIC_NAME} → using shared plan"
        else
            check_warn "${LOGIC_NAME} → using individual plan '${PLAN_NAME}'"
        fi
    done
else
    check_warn "No Logic Apps found"
fi

# Cost Summary
echo -e "\n10. Cost Analysis..."
if [ "${PLAN_COUNT}" -gt 0 ]; then
    TOTAL_PLANS="${PLAN_COUNT}"
    SHARED_WINDOWS=$([[ "${WINDOWS_PLAN_COUNT}" -gt 0 ]] && echo "Yes" || echo "No")
    SHARED_LOGIC=$([[ "${LOGIC_PLAN_COUNT}" -gt 0 ]] && echo "Yes" || echo "No")
    
    echo "   Total App Service Plans: ${TOTAL_PLANS}"
    echo "   Shared Windows Function Plan: ${SHARED_WINDOWS}"
    echo "   Shared Logic App Plan: ${SHARED_LOGIC}"
    
    if [ "${SHARED_WINDOWS}" == "Yes" ] && [ "${SHARED_LOGIC}" == "Yes" ]; then
        check_pass "Using shared plan architecture (cost optimized)"
        echo "   Estimated savings: ~50-60% compared to individual plans"
    elif [ "${SHARED_WINDOWS}" == "Yes" ] || [ "${SHARED_LOGIC}" == "Yes" ]; then
        check_warn "Partially using shared plans"
    else
        check_warn "Not using shared plans (higher costs)"
    fi
fi

# Summary
echo -e "\n=========================================="
echo "Validation Summary"
echo "=========================================="
echo "Environment: ${ENVIRONMENT}"
echo "Resource Group: ${RG_NAME}"
echo "App Service Plans: ${PLAN_COUNT}"
echo "Function Apps: ${FUNC_COUNT}"
echo "Logic Apps: ${LOGIC_COUNT}"
echo "=========================================="
echo -e "${GREEN}Validation Complete!${NC}"
echo "=========================================="

