# App Service Module

This module provisions a secure Azure Linux App Service with managed identity, Application Insights, VNet integration, and optional private endpoint.

## Features

- **Secure by Default**: HTTPS only, TLS 1.2 minimum, FTP disabled
- **Managed Identity**: User-assigned identity for Azure service authentication
- **Network Security**: VNet integration for outbound, optional private endpoint for inbound
- **Monitoring**: Application Insights integration and diagnostic logging
- **Azure DevOps Ready**: Configured for deployment via Azure DevOps pipelines

## Usage

```hcl
module "app_service" {
  source = "../../../../modules/app_service"
  
  project        = "myproject"
  environment    = "dev"
  location       = "West US 2"
  location_short = "wus2"
  
  resource_group_name = azurerm_resource_group.this.name
  sku_name           = "B1"
  
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
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Settings
  always_on = false  # Set to true for production
  
  additional_app_settings = {
    "CUSTOM_SETTING" = "value"
  }
  
  tags = var.tags
}
```

## Security Features

1. **HTTPS Only**: All traffic enforced over HTTPS
2. **TLS 1.2 Minimum**: Modern TLS version required
3. **FTP Disabled**: No FTP access, reducing attack surface
4. **Managed Identity**: No credentials stored in code
5. **VNet Integration**: Outbound traffic through private network
6. **Private Endpoint**: Optional inbound traffic through private network
7. **Key Vault Integration**: Secrets stored in Key Vault, accessed via managed identity

## Azure DevOps Deployment

To deploy from Azure DevOps:

1. Grant the Azure DevOps service connection access to the resource group
2. Use the App Service Deploy task in your pipeline
3. The app is configured with `WEBSITE_RUN_FROM_PACKAGE` for package deployment

Example pipeline step:
```yaml
- task: AzureWebApp@1
  inputs:
    azureSubscription: 'Your-Service-Connection'
    appType: 'webAppLinux'
    appName: '$(appServiceName)'
    package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment (dev, qa, prod) | string | - | yes |
| location | Azure region | string | - | yes |
| location_short | Short name for Azure region | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| sku_name | App Service Plan SKU | string | B1 | no |
| user_assigned_identity_id | Managed identity ID | string | - | yes |
| user_assigned_identity_client_id | Managed identity client ID | string | - | yes |
| app_insights_connection_string | App Insights connection string | string | - | yes |
| key_vault_uri | Key Vault URI | string | - | yes |
| runtime_stack | Runtime stack | string | dotnet | no |
| enable_vnet_integration | Enable VNet integration | bool | true | no |
| subnet_id | VNet integration subnet ID | string | null | no |
| enable_private_endpoint | Enable private endpoint | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| app_service_id | App Service resource ID |
| app_service_name | App Service name |
| app_service_default_hostname | Default hostname |
| service_plan_id | App Service Plan ID |

