#!/bin/bash

# Azure DevOps Environments Creation Script
# This script creates the required environments for pipeline deployments

set -e

# Configuration - UPDATE THESE VALUES
ORGANIZATION="https://dev.azure.com/vikingtechnology"
PROJECT="DEVOPS"

echo "🚀 Creating Azure DevOps Environments..."
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

# Environments to create
ENVIRONMENTS=(
    "evo-taskers-dev"
    "evo-taskers-qa"
    "evo-taskers-prod"
    "evo-taskers-automateddatafeed-dev"
    "evo-taskers-automateddatafeed-qa"
    "evo-taskers-automateddatafeed-prod"
    "evo-taskers-dashboard-dev"
    "evo-taskers-dashboard-qa"
    "evo-taskers-dashboard-prod"
    "evo-taskers-dashboardfrontend-dev"
    "evo-taskers-dashboardfrontend-qa"
    "evo-taskers-dashboardfrontend-prod"
    "evo-taskers-sendgridfunction-dev"
    "evo-taskers-sendgridfunction-qa"
    "evo-taskers-sendgridfunction-prod"
    "evo-taskers-unlockbookings-dev"
    "evo-taskers-unlockbookings-qa"
    "evo-taskers-unlockbookings-prod"
    "evo-taskers-autoopenshorex-dev"
    "evo-taskers-autoopenshorex-qa"
    "evo-taskers-autoopenshorex-prod"
)

echo "Will create ${#ENVIRONMENTS[@]} environments"
echo ""

read -p "Do you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted by user"
    exit 0
fi

echo ""
echo "Creating environments..."
echo ""

# Counter
CREATED=0
SKIPPED=0
FAILED=0

for ENV_NAME in "${ENVIRONMENTS[@]}"; do
    echo -n "Creating environment: $ENV_NAME ... "
    
    # Check if environment already exists
    if az pipelines environment list --query "[?name=='$ENV_NAME'].name" -o tsv 2>/dev/null | grep -q "$ENV_NAME"; then
        echo "⚠️  Already exists, skipping"
        ((SKIPPED++))
        continue
    fi
    
    # Create environment
    if az pipelines environment create --name "$ENV_NAME" --output none 2>/dev/null; then
        echo "✅ Created"
        ((CREATED++))
    else
        echo "❌ Failed"
        ((FAILED++))
    fi
done

echo ""
echo "Summary:"
echo "  ✅ Created: $CREATED"
echo "  ⚠️  Skipped (already exist): $SKIPPED"
echo "  ❌ Failed: $FAILED"
echo ""

if [ $CREATED -gt 0 ] || [ $SKIPPED -gt 0 ]; then
    echo "🎉 Environments are ready!"
    echo ""
    echo "⚠️  IMPORTANT: Configure approvals for production environments:"
    echo ""
    echo "1. Go to Azure DevOps → Pipelines → Environments"
    echo "2. For each *-prod environment:"
    echo "   - Click on the environment name"
    echo "   - Click '...' menu → 'Approvals and checks'"
    echo "   - Add 'Approvals'"
    echo "   - Add approvers"
    echo "   - Set timeout (30 minutes recommended)"
    echo "   - Add instructions for approvers"
    echo ""
    echo "Production environments that need approvals:"
    for ENV_NAME in "${ENVIRONMENTS[@]}"; do
        if [[ "$ENV_NAME" == *"-prod" ]]; then
            echo "  - $ENV_NAME"
        fi
    done
fi

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "⚠️  Some environments failed to create. Please create them manually:"
    echo "   Azure DevOps → Pipelines → Environments → New environment"
fi

echo ""
echo "Next steps:"
echo "1. Configure production approvals (see above)"
echo "2. Run the pipelines to test"
echo "3. Review pipeline execution logs"

