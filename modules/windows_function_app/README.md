# Function App Module

This module provisions a secure Azure Linux Function App with managed identity, Application Insights, VNet integration, and optional private endpoint.

## Features

- **Secure by Default**: HTTPS only, TLS 1.2 minimum, FTP disabled
- **Managed Identity**: User-assigned identity for Azure service authentication
- **Network Security**: VNet integration for outbound, optional private endpoint for inbound
- **Monitoring**: Application Insights integration and diagnostic logging
- **Azure DevOps Ready**: Configured for deployment via Azure DevOps pipelines
- **Multiple Runtimes**: Supports .NET, Node.js, Python, and Java

## Usage

```hcl
module "function_app" {
  source = "../../../../modules/function_app"
  
  project        = "myproject"
  environment    = "dev"
  location       = "West US 2"
  location_short = "wus2"
  
  resource_group_name = azurerm_resource_group.this.name
  sku_name           = "Y1"  # Consumption plan
  
  # Storage (required for Function Apps)
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  # Managed Identity
  user_assigned_identity_id        = var.user_assigned_identity_id
  user_assigned_identity_client_id = var.user_assigned_identity_client_id
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = var.app_integration_subnet_id
  
  enable_private_endpoint    = false  # Set to true for production
  private_endpoint_subnet_id = var.private_endpoints_subnet_id
  
  # Monitoring
  app_insights_connection_string   = var.app_insights_connection_string
  app_insights_instrumentation_key = var.app_insights_instrumentation_key
  log_analytics_workspace_id       = var.log_analytics_workspace_id
  
  # Key Vault
  key_vault_uri = var.key_vault_uri
  
  # Runtime
  functions_worker_runtime = "dotnet"
  dotnet_version          = "8.0"
  
  # Settings
  always_on = false  # Not available on Consumption (Y1)
  
  additional_app_settings = {
    "CUSTOM_SETTING" = "value"
  }
  
  tags = var.tags
}
```

## SKU Options

| SKU | Name | Description | Always On |
|-----|------|-------------|-----------|
| Y1 | Consumption | Pay per execution, auto-scale | ❌ |
| EP1 | Elastic Premium | Pre-warmed workers, VNet, unlimited execution | ✅ |
| B1 | Basic | Dedicated compute, predictable cost | ✅ |
| S1 | Standard | Production workloads | ✅ |

## Security Features

1. **HTTPS Only**: All traffic enforced over HTTPS
2. **TLS 1.2 Minimum**: Modern TLS version required
3. **FTP Disabled**: No FTP access, reducing attack surface
4. **Managed Identity**: No credentials stored in code
5. **VNet Integration**: Outbound traffic through private network
6. **Private Endpoint**: Optional inbound traffic through private network
7. **Key Vault Integration**: Secrets stored in Key Vault, accessed via managed identity

## Runtime Support

### .NET
```hcl
functions_worker_runtime = "dotnet"
dotnet_version          = "8.0"  # Options: 6.0, 7.0, 8.0
```

### Node.js
```hcl
functions_worker_runtime = "node"
node_version            = "18"   # Options: 16, 18, 20
```

### Python
```hcl
functions_worker_runtime = "python"
python_version          = "3.11" # Options: 3.8, 3.9, 3.10, 3.11
```

### Java
```hcl
functions_worker_runtime = "java"
java_version            = "17"   # Options: 11, 17
```

## Azure DevOps Deployment

### Pipeline Example

```yaml
- task: AzureFunctionApp@1
  inputs:
    azureSubscription: 'Your-Service-Connection'
    appType: 'functionAppLinux'
    appName: '$(functionAppName)'
    package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    runtimeStack: 'DOTNET|8.0'
    deploymentMethod: 'zipDeploy'
```

### Deployment Slots (Premium/Dedicated only)

For blue/green deployments:
```yaml
- task: AzureFunctionApp@1
  inputs:
    azureSubscription: 'Your-Service-Connection'
    appType: 'functionAppLinux'
    appName: '$(functionAppName)'
    package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    deployToSlotOrASE: true
    resourceGroupName: '$(resourceGroupName)'
    slotName: 'staging'
```

## Key Vault Integration

### Using App Settings

```hcl
additional_app_settings = {
  "ConnectionString" = "@Microsoft.KeyVault(SecretUri=https://kv-name.vault.azure.net/secrets/db-connection/)"
}
```

### Using Azure SDK

```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var keyVaultUri = Environment.GetEnvironmentVariable("KeyVaultUri");
var client = new SecretClient(
    new Uri(keyVaultUri), 
    new DefaultAzureCredential()
);
```

## Storage Account

Function Apps require a storage account for:
- Function execution metadata
- Timer triggers state
- Durable Functions state (if used)
- Blob/Queue/Table triggers

The storage account is configured via:
- `storage_account_name`
- `storage_account_access_key`

**Security Note**: Consider using managed identity for storage access in production.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment (dev, qa, prod) | string | - | yes |
| location | Azure region | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| sku_name | App Service Plan SKU | string | Y1 | no |
| storage_account_name | Storage account name | string | - | yes |
| storage_account_access_key | Storage account key | string | - | yes |
| user_assigned_identity_id | Managed identity ID | string | - | yes |
| functions_worker_runtime | Worker runtime | string | dotnet | no |
| enable_vnet_integration | Enable VNet integration | bool | true | no |
| enable_private_endpoint | Enable private endpoint | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| function_app_id | Function App resource ID |
| function_app_name | Function App name |
| function_app_default_hostname | Default hostname |
| service_plan_id | App Service Plan ID |

## Best Practices

### Development
- Use Consumption (Y1) plan for cost savings
- Enable VNet integration for accessing private resources
- Use Application Insights for monitoring

### Production
- Use Premium (EP1+) or Dedicated (S1+) for predictable performance
- Enable private endpoints to block public access
- Enable always_on (Premium/Dedicated only)
- Use deployment slots for zero-downtime deployments
- Implement proper retry policies and dead-letter queues

### Security
- Store all secrets in Key Vault
- Use managed identity for authentication
- Enable diagnostic logging
- Restrict CORS origins
- Use latest runtime versions

## Limitations

### Consumption Plan (Y1)
- No always_on support
- 10-minute execution timeout
- No deployment slots
- Cold start possible

### Premium/Dedicated Plans
- Higher cost
- Requires capacity planning
- Full VNet integration support
- Pre-warmed instances

## Troubleshooting

### Function Won't Start
1. Check storage account accessibility
2. Verify Application Insights connection
3. Check runtime version compatibility
4. Review function app logs

### Storage Access Issues
```bash
# Verify storage account is accessible from VNet
az storage account show --name <storage-account-name> --query networkRuleSet

# Check if VNet integration subnet is allowed
```

### Cold Starts (Consumption)
- Consider Premium plan for production
- Implement health check/warmup functions
- Use Application Insights to monitor cold starts

## Examples

See the `project/evo-taskers/unlockbookings/dev/function_app.tf` for a complete example.
