#!/bin/bash

# Azure DevOps Variable Groups Setup Script
# This script creates the required variable groups for Terraform deployments
# Prerequisites: Azure DevOps CLI installed and authenticated

set -e

# Configuration
ORGANIZATION="YOUR_AZURE_DEVOPS_ORG"
PROJECT="YOUR_PROJECT_NAME"

echo "🚀 Creating Azure DevOps Variable Groups for Terraform..."
echo ""
echo "Organization: $ORGANIZATION"
echo "Project: $PROJECT"
echo ""

# Check if Azure DevOps CLI is installed
if ! command -v az devops &> /dev/null; then
    echo "❌ Azure DevOps CLI extension not found!"
    echo "Please install it: az extension add --name azure-devops"
    exit 1
fi

# Configure Azure DevOps CLI defaults
az devops configure --defaults organization=https://dev.azure.com/$ORGANIZATION project=$PROJECT

echo "📦 Creating Variable Group: terraform-backend"
az pipelines variable-group create \
  --name "terraform-backend" \
  --variables \
    BACKEND_RESOURCE_GROUP_NAME="rg-evotaskers-state-pmoss" \
    BACKEND_STORAGE_ACCOUNT_NAME="stevotaskersstatepoc" \
    BACKEND_CONTAINER_NAME="tfstate" \
  --authorize true \
  --description "Terraform backend configuration for state storage"

echo "✅ Variable group 'terraform-backend' created"
echo ""

echo "📦 Creating Variable Group: evo-taskers-common"
az pipelines variable-group create \
  --name "evo-taskers-common" \
  --variables \
    DEV_SERVICE_CONNECTION="Azure-Dev-ServiceConnection" \
    QA_SERVICE_CONNECTION="Azure-QA-ServiceConnection" \
    PROD_SERVICE_CONNECTION="Azure-Prod-ServiceConnection" \
  --authorize true \
  --description "Common infrastructure pipeline variables"

echo "✅ Variable group 'evo-taskers-common' created"
echo ""

echo "📦 Creating Variable Group: evo-taskers-apps"
az pipelines variable-group create \
  --name "evo-taskers-apps" \
  --variables \
    DEV_SERVICE_CONNECTION="Azure-Dev-ServiceConnection" \
    QA_SERVICE_CONNECTION="Azure-QA-ServiceConnection" \
    PROD_SERVICE_CONNECTION="Azure-Prod-ServiceConnection" \
  --authorize true \
  --description "Application workload pipeline variables"

echo "✅ Variable group 'evo-taskers-apps' created"
echo ""

echo "🎉 All variable groups created successfully!"
echo ""
echo "⚠️  IMPORTANT: You need to manually:"
echo "1. Update service connection names in the variable groups to match your actual service connections"
echo "2. Update backend storage account details if different"
echo "3. Configure approvals for production environments in Azure DevOps"
echo ""
echo "📋 Next Steps:"
echo "1. Create Azure Service Connections in Azure DevOps for each environment (Dev/QA/Prod)"
echo "2. Update the service connection names in variable groups"
echo "3. Configure environment approvals: Pipelines -> Environments -> Select Environment -> Approvals and checks"
echo "4. Set up branch policies on main branch to require pull requests"

