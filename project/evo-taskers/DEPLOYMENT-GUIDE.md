# EVO-TASKERS Deployment Guide

## Overview

This guide covers the deployment of EVO-TASKERS infrastructure with the new three-tier architecture:

1. **Common** (Landing Zone) - Networking, identity, storage, monitoring
2. **Shared** (Shared Services) - App Service Plans, Event Hubs, APIM
3. **Apps** (Applications) - Individual application deployments

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  DEPLOYMENT ORDER                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step 1: COMMON (Landing Zone)                             │
│  ├─ Resource Group                                         │
│  ├─ Virtual Network + Subnets                              │
│  ├─ Storage Account                                        │
│  ├─ Key Vault                                              │
│  ├─ Log Analytics                                          │
│  ├─ Application Insights                                   │
│  └─ Managed Identity                                       │
│                                                             │
│  Step 2: SHARED (Shared Services)                          │
│  ├─ Windows Function App Service Plan (EP1)                │
│  └─ Logic App Service Plan (WS1)                           │
│                                                             │
│  Step 3: APPS (Individual Applications)                    │
│  ├─ unlockbookings (Logic App)                             │
│  ├─ automateddatafeed (Function App)                       │
│  ├─ dashboard (Function App)                               │
│  ├─ sendgrid (Function App)                                │
│  └─ autoopenshorex (Function App)                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## State File Organization

```
Azure Storage Account: stevotaskersstatepoc
Container: tfstate

State Files:
├── landing-zone/
│   ├── evo-taskers-common-dev.tfstate
│   ├── evo-taskers-common-qa.tfstate
│   └── evo-taskers-common-prod.tfstate
│
├── shared/
│   ├── evo-taskers-shared-dev.tfstate
│   ├── evo-taskers-shared-qa.tfstate
│   └── evo-taskers-shared-prod.tfstate
│
└── apps/
    ├── unlockbookings-dev.tfstate
    ├── unlockbookings-qa.tfstate
    ├── automateddatafeed-dev.tfstate
    ├── automateddatafeed-prod.tfstate
    └── ...
```

## Prerequisites

1. Azure subscription with appropriate permissions
2. Terraform >= 1.9.0
3. Azure CLI installed and authenticated
4. Backend storage account created (`stevotaskersstatepoc`)

## End-to-End Deployment

### Step 1: Deploy Common Infrastructure (Landing Zone)

```bash
# Navigate to common module
cd project/evo-taskers/common

# Initialize Terraform with dev backend
terraform init

# Review the plan
terraform plan -var-file="dev.tfvars" -out=tfplan

# Apply the plan
terraform apply tfplan

# Verify outputs
terraform output
```

**Expected Outputs:**
- resource_group_name
- vnet_id
- storage_account_name
- key_vault_uri
- workload_identity_id
- app_insights_connection_string

### Step 2: Deploy Shared Services

```bash
# Navigate to shared module
cd ../shared

# Initialize Terraform with dev backend
terraform init

# Review the plan
terraform plan -var-file="dev.tfvars" -out=tfplan

# Apply the plan
terraform apply tfplan

# Verify outputs
terraform output
```

**Expected Outputs:**
- windows_function_plan_id
- windows_function_plan_name
- logic_app_plan_id
- logic_app_plan_name

### Step 3: Deploy Applications

#### Deploy UnlockBookings (Logic App)

```bash
# Navigate to unlockbookings
cd ../unlockbookings

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="dev.tfvars" -out=tfplan

# Apply the plan
terraform apply tfplan

# Verify the Logic App is created and using shared plan
terraform output
```

#### Deploy AutomatedDataFeed (Function App)

```bash
# Navigate to automateddatafeed
cd ../automateddatafeed

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="dev.tfvars" -out=tfplan

# Apply the plan
terraform apply tfplan

# Verify the Function App is created and using shared plan
terraform output
```

## Validation Steps

### 1. Verify Common Infrastructure

```bash
cd project/evo-taskers/common

# Check state
terraform state list

# Verify key resources
az group show --name <resource-group-name>
az network vnet show --name <vnet-name> --resource-group <rg-name>
az keyvault show --name <keyvault-name>
```

### 2. Verify Shared Services

```bash
cd ../shared

# Check state
terraform state list

# Verify App Service Plans
az appservice plan list --resource-group <rg-name> --output table

# Check plan details
az appservice plan show --name <plan-name> --resource-group <rg-name>
```

### 3. Verify Applications

```bash
cd ../unlockbookings

# List Logic Apps
az logicapp list --resource-group <rg-name> --output table

# Check which plan the Logic App is using
az logicapp show --name <logic-app-name> --resource-group <rg-name> \
  --query "{name:name, plan:appServicePlanId}" --output table

cd ../automateddatafeed

# List Function Apps
az functionapp list --resource-group <rg-name> --output table

# Check which plan the Function App is using
az functionapp show --name <function-app-name> --resource-group <rg-name> \
  --query "{name:name, plan:serverFarmId}" --output table
```

### 4. Verify Plan Sharing

Both unlockbookings and automateddatafeed should reference the shared plans:

```bash
# Check that multiple apps share the same plan
az appservice plan show --name <windows-function-plan-name> \
  --resource-group <rg-name> \
  --query "{name:name, sku:sku.name, numberOfSites:numberOfSites}" \
  --output table
```

Expected: `numberOfSites` should be > 1 (showing multiple apps on the plan)

## Validation Script

Create and run this validation script:

```bash
#!/bin/bash
# validate-deployment.sh

ENVIRONMENT="dev"
RG_NAME="rg-evotaskers-${ENVIRONMENT}-eus"

echo "==================================="
echo "EVO-TASKERS Deployment Validation"
echo "Environment: ${ENVIRONMENT}"
echo "==================================="

# 1. Verify Resource Group
echo -e "\n1. Checking Resource Group..."
az group show --name "${RG_NAME}" --query "name" -o tsv && echo "✓ Resource Group exists" || echo "✗ Resource Group not found"

# 2. Verify VNet
echo -e "\n2. Checking Virtual Network..."
az network vnet list --resource-group "${RG_NAME}" --query "[].name" -o tsv && echo "✓ VNet exists" || echo "✗ VNet not found"

# 3. Verify App Service Plans
echo -e "\n3. Checking App Service Plans..."
echo "Windows Function Plan:"
az appservice plan list --resource-group "${RG_NAME}" \
  --query "[?contains(name, 'functions-windows')].{Name:name, SKU:sku.name, Apps:numberOfSites}" -o table

echo -e "\nLogic App Plan:"
az appservice plan list --resource-group "${RG_NAME}" \
  --query "[?contains(name, 'logicapps')].{Name:name, SKU:sku.name, Apps:numberOfSites}" -o table

# 4. Verify Function Apps
echo -e "\n4. Checking Function Apps..."
az functionapp list --resource-group "${RG_NAME}" \
  --query "[].{Name:name, State:state, Plan:appServicePlanId}" -o table

# 5. Verify Logic Apps
echo -e "\n5. Checking Logic Apps..."
az logicapp list --resource-group "${RG_NAME}" \
  --query "[].{Name:name, State:state, Plan:appServicePlanId}" -o table

# 6. Verify Plan Sharing
echo -e "\n6. Verifying Plan Sharing..."
WINDOWS_PLAN_NAME=$(az appservice plan list --resource-group "${RG_NAME}" \
  --query "[?contains(name, 'functions-windows')].name" -o tsv)

if [ -n "${WINDOWS_PLAN_NAME}" ]; then
  APP_COUNT=$(az appservice plan show --name "${WINDOWS_PLAN_NAME}" \
    --resource-group "${RG_NAME}" \
    --query "numberOfSites" -o tsv)
  
  if [ "${APP_COUNT}" -gt 0 ]; then
    echo "✓ Windows Function Plan has ${APP_COUNT} app(s)"
  else
    echo "⚠ Windows Function Plan has no apps"
  fi
fi

echo -e "\n==================================="
echo "Validation Complete!"
echo "==================================="
```

Save and run:
```bash
chmod +x validate-deployment.sh
./validate-deployment.sh
```

## Cost Analysis

### Before (Individual Plans)

```
automateddatafeed:  EP1 Plan = $150/month
dashboard:          EP1 Plan = $150/month
sendgrid:           EP1 Plan = $150/month
autoopenshorex:     EP1 Plan = $150/month
unlockbookings:     WS1 Plan = $225/month

TOTAL: $825/month
```

### After (Shared Plans)

```
Shared Windows Function Plan (EP1):  $150/month
  ├─ automateddatafeed
  ├─ dashboard
  ├─ sendgrid
  └─ autoopenshorex

Shared Logic App Plan (WS1):         $225/month
  └─ unlockbookings

TOTAL: $375/month
SAVINGS: $450/month (55% reduction)
```

## Troubleshooting

### Issue: "State file not found"

**Solution:** Ensure the previous layer is deployed first:
- Deploy `common` before `shared`
- Deploy `shared` before apps

### Issue: "App Service Plan not found"

**Solution:** 
1. Verify shared module is deployed: `cd shared && terraform output`
2. Check state file key matches: `shared/evo-taskers-shared-${environment}.tfstate`

### Issue: "Resource already exists"

**Solution:**
1. Import existing resource: `terraform import <resource_type>.<name> <azure_resource_id>`
2. Or remove from Azure: `az resource delete --ids <resource_id>`

### Issue: Apps can't find shared plan

**Cause:** Remote state configuration mismatch

**Solution:**
1. Verify backend configuration in app's `main.tf`
2. Check state file exists: 
   ```bash
   az storage blob list \
     --account-name stevotaskersstatepoc \
     --container-name tfstate \
     --prefix shared/ \
     --output table
   ```

## Rollback Procedure

If you need to rollback:

### Rollback Shared Services

```bash
cd project/evo-taskers/shared
terraform destroy -var-file="dev.tfvars"
```

**Warning:** This will impact all apps using shared plans!

### Rollback Individual App

```bash
cd project/evo-taskers/unlockbookings
terraform destroy -var-file="dev.tfvars"
```

## Best Practices

1. **Always deploy in order:** common → shared → apps
2. **Use workspaces or tfvars** for multiple environments
3. **Review plans** before applying (use `-out=tfplan`)
4. **Tag resources** consistently for cost tracking
5. **Monitor App Service Plan metrics** (CPU, memory) after deployment
6. **Test in dev** before deploying to prod
7. **Backup state files** regularly

## Next Steps

After successful deployment:

1. Configure application code deployment (Azure DevOps/GitHub Actions)
2. Set up monitoring and alerts
3. Configure auto-scaling rules (if needed)
4. Review and optimize costs
5. Document any custom configurations

## Support

For issues or questions:
- See [modules/MIGRATION-GUIDE.md](../../modules/MIGRATION-GUIDE.md)
- See [modules/QUICK-REFERENCE.md](../../modules/QUICK-REFERENCE.md)
- Review module-specific READMEs

