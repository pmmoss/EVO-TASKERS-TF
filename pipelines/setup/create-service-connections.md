# Azure Service Connections Setup

This document describes how to create Azure Service Connections in Azure DevOps for each environment.

## Overview

Service Connections allow Azure DevOps pipelines to authenticate with Azure and deploy resources. You need separate service connections for each environment (Dev, QA, Prod) to ensure proper isolation and security.

## Prerequisites

- Azure DevOps organization and project
- Azure subscriptions for each environment (or separate resource groups if using single subscription)
- Appropriate permissions in both Azure and Azure DevOps

## Recommended Approach: Separate Subscriptions

**Best Practice**: Use separate Azure subscriptions for Dev, QA, and Prod environments.

### Benefits:
- **Security isolation**: Prevents accidental changes across environments
- **Cost management**: Clear cost separation and chargeback
- **Compliance**: Meets most regulatory requirements
- **Blast radius containment**: Issues in one environment don't affect others

## Step-by-Step: Creating Service Connections

### 1. Navigate to Service Connections

1. Open your Azure DevOps project
2. Go to **Project Settings** (bottom left)
3. Under **Pipelines**, click **Service connections**
4. Click **New service connection**

### 2. Create Development Service Connection

1. Select **Azure Resource Manager**
2. Select **Service principal (automatic)** - Recommended
3. Configure:
   - **Subscription**: Select your Dev subscription
   - **Resource group**: Leave empty (to allow access to entire subscription) or select specific RG
   - **Service connection name**: `Azure-Dev-ServiceConnection`
   - **Description**: `Service connection for Dev environment deployments`
   - **Grant access permission to all pipelines**: ✅ Check this (or configure per-pipeline)
4. Click **Save**

### 3. Create QA Service Connection

Repeat the process with:
- **Subscription**: Your QA subscription
- **Service connection name**: `Azure-QA-ServiceConnection`
- **Description**: `Service connection for QA environment deployments`

### 4. Create Production Service Connection

Repeat the process with:
- **Subscription**: Your Prod subscription
- **Service connection name**: `Azure-Prod-ServiceConnection`
- **Description**: `Service connection for Production environment deployments`

## Alternative: Manual Service Principal Creation

For more control, you can manually create service principals:

```bash
# Create Service Principal for Dev
az ad sp create-for-rbac \
  --name "sp-evo-taskers-dev" \
  --role Contributor \
  --scopes /subscriptions/YOUR-DEV-SUBSCRIPTION-ID \
  --sdk-auth

# Create Service Principal for QA
az ad sp create-for-rbac \
  --name "sp-evo-taskers-qa" \
  --role Contributor \
  --scopes /subscriptions/YOUR-QA-SUBSCRIPTION-ID \
  --sdk-auth

# Create Service Principal for Prod
az ad sp create-for-rbac \
  --name "sp-evo-taskers-prod" \
  --role Contributor \
  --scopes /subscriptions/YOUR-PROD-SUBSCRIPTION-ID \
  --sdk-auth
```

Then in Azure DevOps:
1. Select **Service principal (manual)**
2. Enter the credentials from the output above
3. Configure the service connection name and save

## Minimum Required Permissions

Each service principal needs:

- **Contributor** role on the subscription or resource group
- **User Access Administrator** role if creating role assignments (for RBAC in Terraform)

```bash
# Grant additional permissions if needed
az role assignment create \
  --assignee <service-principal-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>
```

## Subscription Mapping

Update these in your environment:

| Environment | Subscription Name | Subscription ID | Service Connection Name |
|-------------|------------------|-----------------|------------------------|
| Development | Your-Dev-Sub     | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Azure-Dev-ServiceConnection |
| QA          | Your-QA-Sub      | yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy | Azure-QA-ServiceConnection |
| Production  | Your-Prod-Sub    | zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz | Azure-Prod-ServiceConnection |

## Security Best Practices

### 1. Service Principal Rotation
- Rotate service principal credentials every 90 days
- Use Azure Key Vault to store credentials
- Enable auditing on service principals

### 2. Limit Scope
```bash
# Instead of subscription-wide, limit to resource group
az ad sp create-for-rbac \
  --name "sp-evo-taskers-dev" \
  --role Contributor \
  --scopes /subscriptions/SUB-ID/resourceGroups/rg-evo-taskers-dev
```

### 3. Production Restrictions
- **Never** grant "Grant access permission to all pipelines" for Production
- Explicitly configure which pipelines can use the Prod service connection
- Enable approvals and checks on the service connection itself

### 4. Monitoring
- Enable diagnostic logs for service principal sign-ins
- Set up alerts for unusual activity
- Regular access reviews

## Verifying Service Connections

Test each service connection:

```yaml
# test-service-connection.yml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureCLI@2
    displayName: 'Test Service Connection'
    inputs:
      azureSubscription: 'Azure-Dev-ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        echo "Testing service connection..."
        az account show
        az group list --query "[].name" -o table
```

## Troubleshooting

### Issue: "The subscription is disabled"
**Solution**: Ensure the Azure subscription is active and not expired

### Issue: "Insufficient privileges"
**Solution**: Grant Contributor + User Access Administrator roles

### Issue: "Service connection not found"
**Solution**: Ensure service connection names in variable groups match exactly

### Issue: "Failed to acquire token"
**Solution**: Re-authorize the service connection or recreate it

## Next Steps

After creating service connections:

1. ✅ Update variable groups with correct service connection names
2. ✅ Configure environment approvals for Production
3. ✅ Test connections with a simple pipeline
4. ✅ Set up branch policies
5. ✅ Create environments in Azure DevOps

