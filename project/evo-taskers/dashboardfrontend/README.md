# Dashboard Frontend Infrastructure

This Terraform configuration provisions the Azure infrastructure for the Dashboard Frontend web application using the robust linux_web_app module.

## Overview

The Dashboard Frontend is a web application that provides the user interface for the EVO-TASKERS system. This infrastructure configuration deploys:

- **Azure Linux Web App**: Hosting the frontend application
- **App Service Plan**: Compute resources for the web app
- **VNet Integration**: Secure outbound connectivity
- **Private Endpoint**: Secure inbound connectivity (production)
- **Application Insights**: Application performance monitoring
- **Diagnostic Logging**: Comprehensive logging to Log Analytics

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Dashboard Frontend                        │
│                                                              │
│  ┌───────────────┐         ┌──────────────────┐            │
│  │  Linux Web    │────────▶│  App Service     │            │
│  │  App          │         │  Plan            │            │
│  └───────┬───────┘         └──────────────────┘            │
│          │                                                   │
│          │ VNet Integration                                 │
│          ▼                                                   │
│  ┌───────────────────────────────────────────┐             │
│  │     Common Infrastructure Subnets         │             │
│  │  - App Integration Subnet                 │             │
│  │  - Private Endpoints Subnet               │             │
│  └───────────────────────────────────────────┘             │
│                                                              │
│  Monitoring:                                                 │
│  - Application Insights                                      │
│  - Log Analytics Workspace                                   │
│  - Diagnostic Settings                                       │
│                                                              │
│  Security:                                                   │
│  - User-Assigned Managed Identity                           │
│  - Key Vault Integration                                     │
│  - HTTPS Only, TLS 1.2+                                     │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Common Infrastructure**: The common infrastructure must be deployed first:
   ```bash
   cd ../common
   terraform workspace select dev  # or qa/prod
   terraform apply
   ```

2. **Terraform Workspace**: Ensure you're using the correct workspace
3. **Azure Permissions**: Sufficient permissions to create App Services and networking resources

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Select Workspace

```bash
# For development
terraform workspace select dev

# For QA
terraform workspace select qa

# For production
terraform workspace select prod
```

### 3. Plan Deployment

```bash
# Development
terraform plan -var-file="dev.tfvars"

# QA
terraform plan -var-file="qa.tfvars"

# Production
terraform plan -var-file="prod.tfvars"
```

### 4. Apply Configuration

```bash
# Development
terraform apply -var-file="dev.tfvars"

# QA
terraform apply -var-file="qa.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

## Environment Configurations

### Development (dev.tfvars)

- **SKU**: B1 (Basic) - Cost-effective
- **Always On**: Disabled - Save costs
- **Private Endpoint**: Disabled - Public access OK
- **Autoscaling**: Disabled
- **Deployment Slot**: Disabled
- **Monitoring**: Basic logging

**Use Case**: Development and testing with minimal costs

### QA (qa.tfvars)

- **SKU**: P0v3 (Premium) - Better performance
- **Always On**: Enabled
- **Private Endpoint**: Optional
- **Autoscaling**: Optional
- **Deployment Slot**: Enabled - Test slot swapping
- **Monitoring**: Enhanced logging with alerts

**Use Case**: Pre-production testing and validation

### Production (prod.tfvars)

- **SKU**: P1V3 (Premium) - High performance
- **Always On**: Enabled
- **Private Endpoint**: Enabled - Secure access
- **Autoscaling**: Enabled (2-10 instances)
- **Deployment Slot**: Enabled - Blue-green deployments
- **Monitoring**: Comprehensive logging and alerting

**Use Case**: Production workloads with HA and security

## Key Features

### Security

- ✅ HTTPS Only enforcement
- ✅ TLS 1.2 minimum
- ✅ Managed Identity (no credentials in code)
- ✅ Key Vault integration for secrets
- ✅ VNet integration for secure outbound
- ✅ Private endpoint for secure inbound (prod)
- ✅ FTP/FTPS disabled

### High Availability

- ✅ Autoscaling based on CPU/Memory (prod)
- ✅ Multiple instances (prod)
- ✅ Health checks with auto-eviction
- ✅ Auto-heal on failures
- ✅ Always On to keep app warm

### DevOps

- ✅ Deployment slots for zero-downtime deployments
- ✅ Sticky settings for slot-specific configs
- ✅ Application Insights for monitoring
- ✅ Comprehensive diagnostic logging

## Deployment

### Application Deployment

After infrastructure is provisioned, deploy your application:

#### Option 1: Azure CLI

```bash
# Get app name from outputs
APP_NAME=$(terraform output -raw web_app_name)

# Deploy from local folder
az webapp deploy \
  --resource-group rg-evotaskers-dev-eus \
  --name $APP_NAME \
  --src-path ./dist \
  --type zip
```

#### Option 2: Azure DevOps Pipeline

```yaml
- task: AzureWebApp@1
  inputs:
    azureSubscription: 'Your-Service-Connection'
    appType: 'webAppLinux'
    appName: '$(webAppName)'
    package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    deploymentMethod: 'zipDeploy'
```

#### Option 3: GitHub Actions

```yaml
- name: Deploy to Azure Web App
  uses: azure/webapps-deploy@v2
  with:
    app-name: ${{ env.AZURE_WEBAPP_NAME }}
    package: ./dist
```

### Blue-Green Deployment

For production deployments using the staging slot:

```bash
# Get app and slot names
APP_NAME=$(terraform output -raw web_app_name)
SLOT_NAME=$(terraform output -raw staging_slot_name)
RESOURCE_GROUP="rg-evotaskers-prod-eus"

# Deploy to staging slot first
az webapp deploy \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --slot $SLOT_NAME \
  --src-path ./dist \
  --type zip

# Test staging slot
curl https://${APP_NAME}-${SLOT_NAME}.azurewebsites.net/health

# Swap staging to production
az webapp deployment slot swap \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --slot $SLOT_NAME \
  --target-slot production
```

## Configuration

### Runtime Versions

Supported runtimes configured in `variables.tf`:

- **.NET**: 6.0, 7.0, 8.0
- **Node.js**: 16-lts, 18-lts, 20-lts
- **Python**: 3.9, 3.10, 3.11, 3.12

Change in tfvars:
```hcl
runtime_stack  = "dotnet"  # or "node", "python"
dotnet_version = "8.0"
```

### CORS Configuration

Add allowed origins in tfvars:
```hcl
cors_allowed_origins = [
  "https://example.com",
  "https://admin.example.com"
]

cors_support_credentials = false
```

### Application Settings

Add custom settings in tfvars:
```hcl
additional_app_settings = {
  "CUSTOM_SETTING" = "value"
  "API_BASE_URL"   = "https://api.example.com"
}
```

### Connection Strings

Add connection strings (use Key Vault references):
```hcl
connection_strings = [
  {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=https://kv.vault.azure.net/secrets/db-conn)"
  }
]
```

## Monitoring

### View Application Insights

```bash
# Get Application Insights key
terraform output app_insights_key

# View in portal
az portal show --query "instrumentationKey"
```

### View Logs

```bash
APP_NAME=$(terraform output -raw web_app_name)

# Stream logs
az webapp log tail --name $APP_NAME --resource-group rg-evotaskers-dev-eus

# Download logs
az webapp log download --name $APP_NAME --resource-group rg-evotaskers-dev-eus
```

### Health Check Endpoint

Ensure your application exposes a health endpoint:

```http
GET /health

Response: 200 OK
{
  "status": "healthy",
  "version": "1.0.0"
}
```

## Troubleshooting

### Application Won't Start

1. Check application logs:
   ```bash
   az webapp log tail --name $APP_NAME --resource-group $RG_NAME
   ```

2. Verify runtime version matches your application
3. Check Application Settings in portal
4. Verify managed identity has Key Vault access

### Network Connectivity Issues

1. Verify VNet integration is configured
2. Check NSG rules on subnets
3. Verify private endpoint DNS resolution (if using PE)
4. Test from within VNet using bastion host

### Slow Performance

1. Check if Always On is enabled (prod)
2. Review Application Insights performance metrics
3. Consider enabling autoscaling
4. Review App Service Plan SKU

### Deployment Failures

1. Verify package format (zip)
2. Check deployment logs in Kudu (https://{app-name}.scm.azurewebsites.net)
3. Verify sufficient disk space
4. Check for startup errors in logs

## Outputs

After deployment, get important information:

```bash
# Application URL
terraform output web_app_url

# Application Name
terraform output web_app_name

# Staging Slot URL (if enabled)
terraform output staging_slot_default_hostname

# All deployment info
terraform output deployment_info
```

## Cost Optimization

### Development
- Use B1 SKU ($13.14/month)
- Disable Always On
- Disable Private Endpoint
- Disable Autoscaling
- Disable Deployment Slot

**Estimated Cost**: ~$15/month

### Production
- Use P1V3 SKU ($145/month)
- Enable all features
- 2-10 instances with autoscaling

**Estimated Cost**: ~$300-1,500/month (depending on scale)

## Security Best Practices

1. **Always use HTTPS Only** ✅
2. **Never store secrets in code** - Use Key Vault ✅
3. **Use Managed Identity** - No passwords ✅
4. **Enable Private Endpoints** for production ✅
5. **Restrict SCM access** with IP restrictions ✅
6. **Enable diagnostic logging** for audit trails ✅
7. **Use deployment slots** for safe rollouts ✅
8. **Keep runtime updated** to latest secure version ✅

## Maintenance

### Updating Infrastructure

```bash
# Pull latest changes
git pull

# Plan changes
terraform plan -var-file="prod.tfvars"

# Apply changes
terraform apply -var-file="prod.tfvars"
```

### Updating Application

Use deployment slots for zero-downtime:

1. Deploy to staging slot
2. Test staging thoroughly
3. Swap staging → production
4. Monitor for issues
5. Swap back if problems detected

## References

- [Module Documentation](../../../modules/linux_web_app/README.md)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review module documentation
3. Contact platform engineering team

## License

Internal use only - EVO-TASKERS project

