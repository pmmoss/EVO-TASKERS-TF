# UnlockBookings Deployment Guide

## Quick Start

This guide walks you through deploying the UnlockBookings application infrastructure.

### Architecture Overview

```
Common Infrastructure (../../common/dev)
├── VNet & Subnets
├── User-Assigned Managed Identity
├── Key Vault
├── Application Insights
├── Log Analytics
└── Storage Account

UnlockBookings App (./dev)
├── App Service (Linux, .NET 8.0)
└── Function App (Optional)
```

## Prerequisites

### 1. Deploy Common Infrastructure First

```bash
cd project/evo-taskers/common/dev
terraform init
terraform plan
terraform apply
```

This creates:
- Resource Group
- Virtual Network with subnets
- User-Assigned Managed Identity
- Key Vault (with RBAC for the identity)
- Application Insights
- Log Analytics
- Storage Account
- Optional Bastion Host

### 2. Verify Common Outputs

```bash
cd project/evo-taskers/common/dev
terraform output
```

You should see outputs for:
- `workload_identity_id`
- `key_vault_uri`
- `app_insights_connection_string`
- `storage_account_name`
- `Network subnet IDs`

## Deploy UnlockBookings Application

### Step 1: Navigate to UnlockBookings Dev

```bash
cd project/evo-taskers/unlockbookings/dev
```

### Step 2: Review Configuration

Edit `terraform.tfvars`:

```hcl
# App Service Configuration
app_service_sku       = "B1"     # B1, S1, P1V2, etc.
app_service_always_on = false    # true for production

# Runtime
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Health Check
health_check_path = "/health"

# Network Security
enable_private_endpoint = false  # true for production (disables public access)

# Custom App Settings
additional_app_settings = {
  # Add your app-specific settings here
  # Use Key Vault references for secrets:
  # "MySecret" = "@Microsoft.KeyVault(SecretUri=https://kv-name.vault.azure.net/secrets/my-secret/)"
}
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers
- Configure remote state backend
- Initialize modules

### Step 4: Plan Deployment

```bash
terraform plan
```

Review the plan. You should see:
- 1 App Service Plan
- 1 Linux Web App
- Optional: Private Endpoint
- Diagnostic Settings

### Step 5: Deploy

```bash
terraform apply
```

Type `yes` when prompted.

### Step 6: Get Outputs

```bash
terraform output app_service_url
```

Example output:
```
https://app-evotaskers-unlockbookings-dev-wus2.azurewebsites.net
```

## Enable Function App (Optional)

If you need background processing with Azure Functions:

### 1. Uncomment the Module

Edit `function_app.tf` and uncomment the entire `module "function_app"` block.

### 2. Uncomment Outputs

Edit `outputs.tf` and uncomment the function app outputs.

### 3. Apply Changes

```bash
terraform apply
```

## Azure DevOps Deployment

### Setup Service Connection

1. **Create Service Principal**:
   ```bash
   # Get resource group name from common outputs
   RG_NAME=$(cd ../../common/dev && terraform output -raw resource_group_name)
   
   # Get subscription ID
   SUB_ID=$(az account show --query id -o tsv)
   
   # Create service principal
   az ad sp create-for-rbac \
     --name "sp-azdo-unlockbookings-dev" \
     --role contributor \
     --scopes /subscriptions/$SUB_ID/resourceGroups/$RG_NAME
   ```

   Save the output (appId, password, tenant).

2. **Create Service Connection in Azure DevOps**:
   - Go to: Project Settings → Service Connections
   - Click: New Service Connection → Azure Resource Manager
   - Choose: Service Principal (manual)
   - Enter the details from step 1
   - Name it: `Azure-UnlockBookings-Dev`

### Pipeline Configuration

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
    - develop
  paths:
    include:
    - src/UnlockBookings.API/*

variables:
  azureSubscription: 'Azure-UnlockBookings-Dev'
  appServiceName: 'app-evotaskers-unlockbookings-dev-wus2'
  buildConfiguration: 'Release'
  dotnetVersion: '8.x'

stages:
- stage: Build
  displayName: 'Build Application'
  jobs:
  - job: Build
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: UseDotNet@2
      displayName: 'Install .NET SDK'
      inputs:
        version: '$(dotnetVersion)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet Packages'
      inputs:
        command: 'restore'
        projects: 'src/UnlockBookings.API/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build Application'
      inputs:
        command: 'build'
        projects: 'src/UnlockBookings.API/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run Tests'
      inputs:
        command: 'test'
        projects: 'tests/**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish Application'
      inputs:
        command: 'publish'
        publishWebProjects: false
        projects: 'src/UnlockBookings.API/*.csproj'
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifacts'
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: Deploy
  displayName: 'Deploy to Dev'
  dependsOn: Build
  condition: succeeded()
  
  jobs:
  - deployment: DeployApp
    displayName: 'Deploy App Service'
    environment: 'unlockbookings-dev'
    pool:
      vmImage: 'ubuntu-latest'
    
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            displayName: 'Deploy to Azure App Service'
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'webAppLinux'
              appName: '$(appServiceName)'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              runtimeStack: 'DOTNETCORE|8.0'
              startUpCommand: ''
```

### Get App Service Name

```bash
terraform output -raw app_service_name
```

Update the `appServiceName` variable in the pipeline.

## Application Configuration

### Adding Secrets to Key Vault

```bash
# Get Key Vault name
KV_NAME=$(cd ../../common/dev && terraform output -raw key_vault_name)

# Add a secret
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "DatabaseConnectionString" \
  --value "Server=myserver;Database=mydb;..."
```

### Reference Secrets in App Settings

Update `terraform.tfvars`:

```hcl
additional_app_settings = {
  "ConnectionStrings__Database" = "@Microsoft.KeyVault(SecretUri=https://${KV_NAME}.vault.azure.net/secrets/DatabaseConnectionString/)"
}
```

Then run:
```bash
terraform apply
```

### Using Managed Identity in Code

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

// Get Key Vault URI from environment
var keyVaultUri = Environment.GetEnvironmentVariable("KeyVaultUri");

// Create client using managed identity
var client = new SecretClient(
    new Uri(keyVaultUri),
    new DefaultAzureCredential()
);

// Get secret
var secret = await client.GetSecretAsync("DatabaseConnectionString");
var connectionString = secret.Value.Value;
```

The `DefaultAzureCredential` automatically uses the user-assigned managed identity.

## Monitoring & Troubleshooting

### View Application Logs

#### Azure Portal
1. Navigate to: App Service → Monitoring → Log Stream
2. Or: App Service → Monitoring → Logs (Application Insights)

#### Azure CLI
```bash
APP_NAME=$(terraform output -raw app_service_name)

# Stream live logs
az webapp log tail --name $APP_NAME --resource-group $RG_NAME

# Download logs
az webapp log download --name $APP_NAME --resource-group $RG_NAME
```

### Check Application Insights

```bash
# Get Application Insights name
AI_NAME=$(cd ../../common/dev && terraform output -raw app_insights_name)

# Query recent exceptions
az monitor app-insights query \
  --app $AI_NAME \
  --analytics-query "exceptions | take 10"
```

### Common Issues

#### App Won't Start

1. **Check logs**: `az webapp log tail --name $APP_NAME --resource-group $RG_NAME`
2. **Verify secrets**: Ensure all Key Vault secrets exist
3. **Check identity permissions**: Verify managed identity has Key Vault access

#### Can't Access Key Vault

```bash
# Get identity principal ID
IDENTITY_ID=$(cd ../../common/dev && terraform output -raw workload_identity_principal_id)

# Verify role assignment
az role assignment list \
  --assignee $IDENTITY_ID \
  --scope /subscriptions/$SUB_ID/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/$KV_NAME
```

Should show "Key Vault Secrets User" role.

#### Deployment Fails

1. **Check service principal permissions**: Ensure it has Contributor on resource group
2. **Verify package**: Ensure the .zip file is valid
3. **Check App Service state**: `az webapp show --name $APP_NAME --resource-group $RG_NAME`

## Security Best Practices

### Development Environment

- ✅ VNet integration enabled
- ✅ User-assigned managed identity
- ✅ All secrets in Key Vault
- ✅ HTTPS only
- ✅ TLS 1.2 minimum
- ✅ Application Insights enabled
- ⚠️ Public access enabled (for ease of testing)

### Production Environment

Update `terraform.tfvars`:

```hcl
# Use higher SKU
app_service_sku = "P1V2"  # or "S1"

# Enable always on
app_service_always_on = true

# Enable private endpoint (blocks public access)
enable_private_endpoint = true
```

Additional recommendations:
- Enable custom domain with managed certificate
- Configure auto-scaling rules
- Set up backup/restore policy
- Enable diagnostic settings
- Configure alerts in Application Insights
- Implement deployment slots for zero-downtime deployments

## Clean Up

### Destroy UnlockBookings App Only

```bash
cd project/evo-taskers/unlockbookings/dev
terraform destroy
```

### Destroy Everything (Including Common Infrastructure)

```bash
# First destroy app
cd project/evo-taskers/unlockbookings/dev
terraform destroy

# Then destroy common infrastructure
cd ../../common/dev
terraform destroy
```

**Warning**: This will delete all resources including the Key Vault (which has soft-delete enabled).

## Next Steps

1. **Deploy your application code** using Azure DevOps pipeline
2. **Configure custom domain** and SSL certificate
3. **Set up monitoring alerts** in Application Insights
4. **Enable auto-scaling** for production workloads
5. **Configure deployment slots** for staging/production
6. **Set up backup** for App Service

## Support

For issues or questions:
- Check Application Insights → Failures
- Review Azure Portal → Activity Log
- Check Terraform state: `terraform show`
- Review module README files in `/modules`

## Resources

- [App Service Module README](../../../../modules/app_service/README.md)
- [Function App Module README](../../../../modules/function_app/README.md)
- [UnlockBookings Dev README](./dev/README.md)

