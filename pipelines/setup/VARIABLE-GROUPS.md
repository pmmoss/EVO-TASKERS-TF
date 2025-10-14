# Azure DevOps Variable Groups Configuration

This document describes the variable groups required for the Terraform pipelines.

## Overview

Variable groups centralize configuration values used across multiple pipelines. They provide a single source of truth for environment-specific settings.

## Required Variable Groups

### 1. terraform-backend

Contains configuration for Terraform state storage backend.

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `BACKEND_RESOURCE_GROUP_NAME` | Resource group containing state storage | `rg-evotaskers-state-pmoss` |
| `BACKEND_STORAGE_ACCOUNT_NAME` | Storage account for Terraform state | `stevotaskersstatepoc` |
| `BACKEND_CONTAINER_NAME` | Blob container name for state files | `tfstate` |
| `BACKEND_SUBSCRIPTION_ID` | Subscription ID where backend resources exist | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

**Scope**: Used by all pipelines
**Authorization**: Allow access to all pipelines

### 2. evo-taskers-common

Contains configuration for common/landing zone infrastructure deployments.

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `DEV_SERVICE_CONNECTION` | Service connection for Dev environment | `Azure-Dev-ServiceConnection` |
| `QA_SERVICE_CONNECTION` | Service connection for QA environment | `Azure-QA-ServiceConnection` |
| `PROD_SERVICE_CONNECTION` | Service connection for Prod environment | `Azure-Prod-ServiceConnection` |
| `DEV_SUBSCRIPTION_ID` | Azure subscription ID for Dev | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `QA_SUBSCRIPTION_ID` | Azure subscription ID for QA | `yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` |
| `PROD_SUBSCRIPTION_ID` | Azure subscription ID for Prod | `zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz` |

**Scope**: Used by landing-zone-pipeline.yml
**Authorization**: Allow access to specific pipelines only

### 3. evo-taskers-apps

Contains configuration for application workload deployments.

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `DEV_SERVICE_CONNECTION` | Service connection for Dev environment | `Azure-Dev-ServiceConnection` |
| `QA_SERVICE_CONNECTION` | Service connection for QA environment | `Azure-QA-ServiceConnection` |
| `PROD_SERVICE_CONNECTION` | Service connection for Prod environment | `Azure-Prod-ServiceConnection` |
| `DEV_SUBSCRIPTION_ID` | Azure subscription ID for Dev | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `QA_SUBSCRIPTION_ID` | Azure subscription ID for QA | `yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy` |
| `PROD_SUBSCRIPTION_ID` | Azure subscription ID for Prod | `zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz` |

**Scope**: Used by applications-pipeline.yml
**Authorization**: Allow access to specific pipelines only

## Creating Variable Groups

### Option 1: Using Azure DevOps CLI (Automated)

```bash
# Run the provided script
cd pipelines/setup
chmod +x create-variable-groups.sh
./create-variable-groups.sh
```

### Option 2: Using Azure DevOps UI (Manual)

1. Navigate to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Enter the variable group name
4. Add variables as key-value pairs
5. Enable **Allow access to all pipelines** (or configure specific pipelines)
6. Click **Save**

#### Creating terraform-backend Variable Group

```
Name: terraform-backend
Description: Terraform backend configuration for state storage

Variables:
├── BACKEND_RESOURCE_GROUP_NAME    = rg-evotaskers-state-pmoss
├── BACKEND_STORAGE_ACCOUNT_NAME   = stevotaskersstatepoc
├── BACKEND_CONTAINER_NAME         = tfstate
└── BACKEND_SUBSCRIPTION_ID        = <your-subscription-id>
```

#### Creating evo-taskers-common Variable Group

```
Name: evo-taskers-common
Description: Common infrastructure pipeline variables

Variables:
├── DEV_SERVICE_CONNECTION     = Azure-Dev-ServiceConnection
├── QA_SERVICE_CONNECTION      = Azure-QA-ServiceConnection
├── PROD_SERVICE_CONNECTION    = Azure-Prod-ServiceConnection
├── DEV_SUBSCRIPTION_ID        = <dev-subscription-id>
├── QA_SUBSCRIPTION_ID         = <qa-subscription-id>
└── PROD_SUBSCRIPTION_ID       = <prod-subscription-id>
```

#### Creating evo-taskers-apps Variable Group

```
Name: evo-taskers-apps
Description: Application workload pipeline variables

Variables:
├── DEV_SERVICE_CONNECTION     = Azure-Dev-ServiceConnection
├── QA_SERVICE_CONNECTION      = Azure-QA-ServiceConnection
├── PROD_SERVICE_CONNECTION    = Azure-Prod-ServiceConnection
├── DEV_SUBSCRIPTION_ID        = <dev-subscription-id>
├── QA_SUBSCRIPTION_ID         = <qa-subscription-id>
└── PROD_SUBSCRIPTION_ID       = <prod-subscription-id>
```

## Variable Group Linking with Azure Key Vault

For sensitive values, you can link variable groups to Azure Key Vault:

### Step 1: Create Key Vault Secrets

```bash
# Create secrets in Key Vault
az keyvault secret set --vault-name <your-keyvault> --name "backend-subscription-id" --value "<sub-id>"
az keyvault secret set --vault-name <your-keyvault> --name "dev-subscription-id" --value "<dev-sub-id>"
az keyvault secret set --vault-name <your-keyvault> --name "qa-subscription-id" --value "<qa-sub-id>"
az keyvault secret set --vault-name <your-keyvault> --name "prod-subscription-id" --value "<prod-sub-id>"
```

### Step 2: Link Variable Group to Key Vault

1. Create or edit variable group in Azure DevOps
2. Enable **Link secrets from an Azure key vault as variables**
3. Select your Azure subscription and Key Vault
4. Click **Authorize** to grant permissions
5. Add secrets as variables

Example:
```
Variable Group: terraform-backend-secrets
Link to Key Vault: kv-devops-secrets

Secrets:
├── backend-subscription-id → BACKEND_SUBSCRIPTION_ID
├── dev-subscription-id → DEV_SUBSCRIPTION_ID
├── qa-subscription-id → QA_SUBSCRIPTION_ID
└── prod-subscription-id → PROD_SUBSCRIPTION_ID
```

## Environment-Specific Overrides

For environment-specific variables, use separate variable groups:

```
terraform-backend-dev
terraform-backend-qa
terraform-backend-prod
```

Then in your pipeline:

```yaml
variables:
  - group: 'terraform-backend'
  - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/develop') }}:
    - group: 'terraform-backend-dev'
  - ${{ if eq(variables['Build.SourceBranch'], 'refs/heads/main') }}:
    - group: 'terraform-backend-prod'
```

## Security Best Practices

### 1. Principle of Least Privilege
- Only grant pipeline access to variable groups it needs
- Don't use "Allow access to all pipelines" for production groups

### 2. Secret Management
- Store sensitive values in Azure Key Vault
- Never commit secrets to source control
- Rotate secrets regularly

### 3. Audit and Monitoring
- Enable audit logs for variable group changes
- Review access periodically
- Monitor for unauthorized access

### 4. Production Protection
- Require approvals before accessing production variable groups
- Separate production variable groups from dev/qa
- Use separate Key Vaults for production secrets

## Updating Variable Groups

### Via Azure DevOps CLI

```bash
# Update a variable in a variable group
az pipelines variable-group variable update \
  --group-name "terraform-backend" \
  --name "BACKEND_STORAGE_ACCOUNT_NAME" \
  --value "new-storage-account-name"
```

### Via Azure DevOps UI

1. Navigate to **Pipelines** → **Library**
2. Click on the variable group name
3. Edit the variable value
4. Click **Save**

## Validation

After creating variable groups, validate they're configured correctly:

```yaml
# validate-variables.yml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: 'terraform-backend'
  - group: 'evo-taskers-common'

steps:
  - task: Bash@3
    displayName: 'Validate Variables'
    inputs:
      targetType: 'inline'
      script: |
        echo "Validating variable groups..."
        
        # Check terraform-backend variables
        echo "Backend Resource Group: $(BACKEND_RESOURCE_GROUP_NAME)"
        echo "Backend Storage Account: $(BACKEND_STORAGE_ACCOUNT_NAME)"
        echo "Backend Container: $(BACKEND_CONTAINER_NAME)"
        
        # Check service connections
        echo "Dev Service Connection: $(DEV_SERVICE_CONNECTION)"
        echo "QA Service Connection: $(QA_SERVICE_CONNECTION)"
        echo "Prod Service Connection: $(PROD_SERVICE_CONNECTION)"
        
        # Validate required variables are set
        required_vars=(
          "BACKEND_RESOURCE_GROUP_NAME"
          "BACKEND_STORAGE_ACCOUNT_NAME"
          "BACKEND_CONTAINER_NAME"
          "DEV_SERVICE_CONNECTION"
        )
        
        for var in "${required_vars[@]}"; do
          if [ -z "${!var}" ]; then
            echo "##vso[task.logissue type=error]Required variable $var is not set!"
            exit 1
          fi
        done
        
        echo "✅ All required variables are configured"
```

## Troubleshooting

### Issue: Variable not found in pipeline
**Solution**: Ensure variable group is linked in pipeline YAML under `variables` section

### Issue: Access denied to variable group
**Solution**: Enable "Allow access to all pipelines" or explicitly authorize the pipeline

### Issue: Key Vault secrets not loading
**Solution**: Verify service connection has "Get" and "List" permissions on Key Vault secrets

### Issue: Variables showing as empty
**Solution**: Check variable names match exactly (case-sensitive)

## Next Steps

After configuring variable groups:

1. ✅ Test variables with validation pipeline
2. ✅ Update service connection names to match your environment
3. ✅ Configure Key Vault linking for secrets
4. ✅ Set up environment-specific overrides if needed
5. ✅ Document your specific subscription IDs and names

