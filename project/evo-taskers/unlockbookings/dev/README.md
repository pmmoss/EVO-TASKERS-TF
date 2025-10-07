# UnlockBookings - Development Environment

This Terraform configuration deploys the UnlockBookings Function App in the Dev environment for background job processing.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Common Infrastructure                      │
│  (VNet, Subnets, Key Vault, App Insights, Identity)        │
│                  (Managed Separately)                        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Remote State Reference
                   │
┌──────────────────▼──────────────────────────────────────────┐
│         UnlockBookings Function App                         │
│                                                              │
│  ┌──────────────────────────────────────────┐              │
│  │         Function App (Linux)             │              │
│  │                                           │              │
│  │  • .NET 8.0 (Isolated)                   │              │
│  │  • User-Assigned Managed Identity        │              │
│  │  • VNet Integration                      │              │
│  │  • Application Insights                  │              │
│  │  • Storage Account Access                │              │
│  │  • Key Vault Access                      │              │
│  │  • Private Endpoint (optional)           │              │
│  └──────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Security Features

### ✅ Secure by Default

1. **HTTPS Only**: All traffic enforced over HTTPS
2. **TLS 1.2 Minimum**: Modern TLS version required
3. **FTP Disabled**: No FTP access
4. **Managed Identity**: User-assigned identity from common infrastructure
5. **VNet Integration**: Outbound traffic through private network
6. **Private Endpoint Support**: Optional inbound traffic isolation (production)
7. **Key Vault Integration**: Secrets managed in Key Vault
8. **Application Insights**: Full monitoring and diagnostics

### 🔐 Authentication & Authorization

- **User-Assigned Managed Identity**: Shared identity from common infrastructure
- **RBAC**: Identity has access to:
  - Key Vault (Secrets User)
  - Storage Account (Blob Data Contributor)
- **No Credentials in Code**: All authentication via managed identity

### 🌐 Network Security

- **VNet Integration**: Apps can access private resources
- **Private Endpoints**: Optional for production (blocks public access)
- **Subnet Delegation**: Apps run in dedicated subnets
- **Network Security Groups**: Managed by network module

## Prerequisites

1. **Common Infrastructure Deployed**: 
   - Navigate to `../../common/dev/` and deploy first
   - This creates VNet, Key Vault, App Insights, etc.

2. **Azure CLI**: Authenticated and configured
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Terraform**: Version 1.5+ installed

## Deployment

### Initial Setup

1. **Initialize Terraform**:
   ```bash
   cd project/evo-taskers/unlockbookings/dev
   terraform init
   ```

2. **Review Configuration**:
   - Edit `terraform.tfvars` for your settings
   - Review `app_service.tf` and `function_app.tf`

3. **Plan Deployment**:
   ```bash
   terraform plan
   ```

4. **Apply Configuration**:
   ```bash
   terraform apply
   ```

### Enabling Function App

The Function App is commented out by default. To enable:

1. Uncomment the module in `function_app.tf`
2. Uncomment the outputs in `outputs.tf`
3. Run `terraform apply`

## Configuration

### App Service Settings

Edit `terraform.tfvars`:

```hcl
# App Service tier (B1, S1, P1V2, etc.)
app_service_sku = "B1"

# Always on (important for production)
app_service_always_on = false  # true for production

# Runtime
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Health check endpoint
health_check_path = "/health"

# CORS (add your frontend URLs)
cors_allowed_origins = [
  "https://your-frontend.azurewebsites.net"
]
```

### Application Settings

Add custom app settings in `terraform.tfvars`:

```hcl
additional_app_settings = {
  "MyApiKey"           = "@Microsoft.KeyVault(SecretUri=https://kv.vault.azure.net/secrets/mykey/)"
  "FeatureFlag_NewUI"  = "true"
  "MaxRetryAttempts"   = "3"
}
```

**Note**: Use Key Vault references for secrets:
- Format: `@Microsoft.KeyVault(SecretUri=<secret-uri>)`
- Managed identity automatically authenticates

### Network Security

For production, enable private endpoints:

```hcl
enable_private_endpoint = true
```

This will:
- Disable public access
- Create private endpoint in private endpoints subnet
- App only accessible via VNet or VPN/ExpressRoute

## Azure DevOps Deployment

### Service Connection Setup

1. **Create Service Principal** (if not exists):
   ```bash
   az ad sp create-for-rbac --name "sp-azdo-unlockbookings-dev" \
     --role contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/{rg-name}
   ```

2. **Create Azure DevOps Service Connection**:
   - Go to Project Settings → Service Connections
   - New Service Connection → Azure Resource Manager
   - Service Principal (manual)
   - Enter SP details from step 1

### Pipeline Configuration

Example Azure DevOps pipeline:

```yaml
trigger:
  branches:
    include:
    - develop
  paths:
    include:
    - src/UnlockBookings.API/*

variables:
  azureSubscription: 'your-service-connection-name'
  appServiceName: 'app-evotaskers-unlockbookings-dev-wus2'  # Get from outputs
  buildConfiguration: 'Release'

stages:
- stage: Build
  jobs:
  - job: Build
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: UseDotNet@2
      inputs:
        version: '8.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        projects: 'src/UnlockBookings.API/*.csproj'
        arguments: '--configuration $(buildConfiguration)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish'
      inputs:
        command: 'publish'
        publishWebProjects: false
        projects: 'src/UnlockBookings.API/*.csproj'
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: Deploy
  dependsOn: Build
  jobs:
  - deployment: DeployApp
    environment: 'dev'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: '$(azureSubscription)'
              appType: 'webAppLinux'
              appName: '$(appServiceName)'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              runtimeStack: 'DOTNETCORE|8.0'
```

### Deployment Permissions

The service principal needs:
- **Contributor** on the Resource Group (or App Service)
- Automatically granted when created with `--role contributor`

### Getting the App Service Name

After Terraform deployment:
```bash
terraform output app_service_name
```

Or check Azure Portal → Resource Group → App Service

## Accessing Secrets from Application

### Using Key Vault References

In app settings (configured via Terraform):
```hcl
additional_app_settings = {
  "ConnectionString" = "@Microsoft.KeyVault(SecretUri=https://kv-name.vault.azure.net/secrets/db-connection/)"
}
```

### Using Azure SDK in Code

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var keyVaultUri = Environment.GetEnvironmentVariable("KeyVaultUri");
var client = new SecretClient(
    new Uri(keyVaultUri), 
    new DefaultAzureCredential()  // Uses managed identity
);

var secret = await client.GetSecretAsync("my-secret");
```

The `DefaultAzureCredential` will automatically use the user-assigned managed identity when running in Azure.

## Monitoring

### Application Insights

Automatically configured for:
- Request tracking
- Dependency tracking
- Exception logging
- Performance monitoring

Connection string automatically injected via:
```
APPLICATIONINSIGHTS_CONNECTION_STRING
```

### Diagnostic Logs

Logs sent to Log Analytics workspace:
- HTTP logs
- Console logs
- Application logs
- Audit logs

View in Azure Portal → App Service → Monitoring → Log Stream

## Troubleshooting

### App Won't Start

1. Check Application Insights → Failures
2. Check Log Stream in Azure Portal
3. Verify all Key Vault secrets exist
4. Verify managed identity has Key Vault access

### Can't Access Key Vault

Verify RBAC assignment:
```bash
# Get the app's managed identity ID
terraform output

# Check Key Vault access policies or RBAC
az role assignment list --scope /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{kv-name}
```

### Network Issues

If apps can't communicate:
- Verify VNet integration is enabled
- Check NSG rules
- Verify subnet has capacity
- Check if private endpoints are blocking access

## Outputs

After deployment, useful outputs:

```bash
# App Service details
terraform output app_service_name
terraform output app_service_url
terraform output app_service_default_hostname

# Service Plan
terraform output service_plan_name
```

## Clean Up

To destroy the infrastructure:

```bash
terraform destroy
```

**Note**: This only destroys the app, not the common infrastructure.

## Support

For issues or questions:
- Check Azure Portal → Resource Group → Activity Log
- Review Application Insights → Failures
- Check Terraform state: `terraform show`

## Next Steps

1. **Deploy Application Code**: Use Azure DevOps pipeline
2. **Configure Secrets**: Add secrets to Key Vault
3. **Set up Custom Domain**: Configure custom domain and SSL
4. **Enable Autoscaling**: For production workloads
5. **Configure Backup**: Enable App Service backup

