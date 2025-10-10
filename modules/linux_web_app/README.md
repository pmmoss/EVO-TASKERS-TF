# Linux Web App Module

A comprehensive, production-ready Terraform module for provisioning secure Azure Linux Web Apps with enterprise features including autoscaling, high availability, monitoring, and advanced networking.

## Features

### 🔒 Security
- **HTTPS Only**: Enforced HTTPS for all traffic
- **TLS 1.2+**: Modern TLS version requirements
- **Managed Identity**: Support for System-assigned, User-assigned, or both
- **Client Certificates**: Optional client certificate authentication
- **IP Restrictions**: Granular IP-based access controls for app and SCM
- **Azure AD Authentication**: Built-in authentication with Azure Active Directory
- **Key Vault Integration**: Secure secret management via Key Vault references
- **FTP Disabled**: Reduced attack surface by default

### 🌐 Networking
- **VNet Integration**: Secure outbound traffic through private network
- **Private Endpoints**: Secure inbound traffic through private network
- **Public Network Control**: Granular control over public access
- **Custom Domains**: Support for custom domains with SSL certificates
- **CORS Configuration**: Flexible cross-origin resource sharing

### 📊 Monitoring & Observability
- **Application Insights**: Integrated application performance monitoring
- **Diagnostic Settings**: Comprehensive logging to Log Analytics, Storage, or Event Hub
- **Metric Alerts**: Built-in alerts for CPU, memory, response time, and errors
- **Health Checks**: Automated health monitoring with eviction policies
- **Auto-Heal**: Automatic recovery from failures

### 🚀 High Availability & Performance
- **Autoscaling**: Automatic scaling based on CPU and memory metrics
- **Zone Redundancy**: Multi-zone deployment for high availability (Premium SKUs)
- **Always On**: Keep apps warm for better performance
- **Load Balancing**: Multiple load balancing strategies
- **Deployment Slots**: Blue-green deployments with staging slots

### 🔧 Development & Operations
- **Multiple Runtime Stacks**: .NET, Node.js, Python, Java, Ruby, PHP, Go, Docker
- **Backup & Restore**: Automated backup configuration
- **Storage Mounts**: Azure Storage account mounting
- **Remote Debugging**: VS2022 remote debugging support
- **Detailed Logging**: Application, HTTP, and platform logs
- **Flexible Service Plans**: Create new or use existing App Service Plans

## Usage

### Basic Example

```hcl
module "linux_web_app" {
  source = "../../../../modules/linux_web_app"
  
  # Required variables
  project        = "myproject"
  app_name       = "api"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.this.name
  
  # Runtime configuration
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Identity
  identity_type                    = "UserAssigned"
  user_assigned_identity_ids       = [azurerm_user_assigned_identity.this.id]
  user_assigned_identity_client_id = azurerm_user_assigned_identity.this.client_id
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = azurerm_subnet.app_integration.id
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.this.connection_string
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  
  tags = local.tags
}
```

### Production Example with All Features

```hcl
module "linux_web_app_production" {
  source = "../../../../modules/linux_web_app"
  
  # Basic Configuration
  project        = "myproject"
  app_name       = "api"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.this.name
  
  # App Service Plan
  sku_name       = "P1V3"
  zone_redundant = true
  worker_count   = 3
  
  # Autoscaling
  enable_autoscale           = true
  autoscale_min_capacity     = 3
  autoscale_max_capacity     = 10
  autoscale_default_capacity = 3
  autoscale_cpu_threshold_up = 70
  autoscale_cpu_threshold_down = 30
  
  # Runtime
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Identity
  identity_type                    = "SystemAssigned, UserAssigned"
  user_assigned_identity_ids       = [azurerm_user_assigned_identity.this.id]
  user_assigned_identity_client_id = azurerm_user_assigned_identity.this.client_id
  key_vault_reference_identity_id  = azurerm_user_assigned_identity.this.id
  
  # Networking
  https_only                    = true
  public_network_access_enabled = false
  enable_vnet_integration       = true
  subnet_id                     = azurerm_subnet.app_integration.id
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.private_endpoints.id
  
  # IP Restrictions
  ip_restrictions = [
    {
      name       = "AllowFrontDoor"
      service_tag = "AzureFrontDoor.Backend"
      priority   = 100
      action     = "Allow"
      headers = {
        x_azure_fdid = [var.frontdoor_id]
      }
    }
  ]
  
  # Security
  client_certificate_enabled = true
  client_certificate_mode    = "Required"
  minimum_tls_version        = "1.2"
  
  # Site Configuration
  always_on          = true
  ftps_state         = "Disabled"
  http2_enabled      = true
  websockets_enabled = false
  use_32_bit_worker  = false
  
  # Health Check
  health_check_path          = "/health"
  health_check_eviction_time = 5
  
  # Auto-Heal
  enable_auto_heal                           = true
  auto_heal_action_type                      = "Recycle"
  auto_heal_trigger_requests_count           = 70
  auto_heal_trigger_requests_interval        = "00:01:00"
  auto_heal_minimum_process_execution_time   = "00:01:00"
  
  # CORS
  cors_allowed_origins     = ["https://app.example.com"]
  cors_support_credentials = false
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.this.connection_string
  key_vault_uri                  = azurerm_key_vault.this.vault_uri
  
  # Diagnostics
  enable_diagnostics         = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  diagnostic_log_categories = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceAuditLogs",
    "AppServicePlatformLogs"
  ]
  
  # Alerts
  enable_alerts                  = true
  alert_action_group_id          = azurerm_monitor_action_group.this.id
  alert_cpu_threshold            = 80
  alert_memory_threshold         = 85
  alert_response_time_threshold  = 5
  alert_http_errors_threshold    = 10
  
  # Backup
  enable_backup               = true
  backup_storage_account_url  = "${azurerm_storage_account.backup.primary_blob_endpoint}${azurerm_storage_container.backup.name}${data.azurerm_storage_account_sas.backup.sas}"
  backup_frequency_interval   = 1
  backup_frequency_unit       = "Day"
  backup_retention_period_days = 30
  
  # Deployment Slots
  create_staging_slot = true
  staging_slot_name   = "staging"
  
  # Custom Domains
  custom_domains = [
    {
      hostname       = "api.example.com"
      certificate_id = azurerm_app_service_certificate.this.id
      ssl_state      = "SniEnabled"
    }
  ]
  
  # App Settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "CUSTOM_SETTING"         = "value"
  }
  
  # Connection Strings
  connection_strings = [
    {
      name  = "DefaultConnection"
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection.id})"
    }
  ]
  
  # Sticky Settings (for deployment slots)
  sticky_app_setting_names = [
    "ASPNETCORE_ENVIRONMENT"
  ]
  
  tags = local.tags
}
```

### Using Existing App Service Plan

```hcl
module "linux_web_app_shared_plan" {
  source = "../../../../modules/linux_web_app"
  
  # Basic Configuration
  project        = "myproject"
  app_name       = "worker"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.this.name
  
  # Use existing App Service Plan
  create_service_plan      = false
  existing_service_plan_id = azurerm_service_plan.shared.id
  
  # Other configurations...
}
```

### Container Deployment

```hcl
module "linux_web_app_container" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "container-app"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.this.name
  
  # Container runtime
  runtime_stack        = "docker"
  docker_image_name    = "myapp:latest"
  docker_registry_url  = "https://myregistry.azurecr.io"
  
  # Use managed identity for ACR authentication
  container_registry_use_managed_identity       = true
  container_registry_managed_identity_client_id = azurerm_user_assigned_identity.this.client_id
  
  # Identity
  identity_type              = "UserAssigned"
  user_assigned_identity_ids = [azurerm_user_assigned_identity.this.id]
  
  # Other configurations...
}
```

### Azure AD Authentication

```hcl
module "linux_web_app_with_auth" {
  source = "../../../../modules/linux_web_app"
  
  # Basic configuration...
  
  # Enable Azure AD Authentication
  enable_auth                    = true
  auth_require_authentication    = true
  auth_unauthenticated_action    = "RedirectToLoginPage"
  auth_default_provider          = "AzureActiveDirectory"
  auth_active_directory_enabled  = true
  auth_aad_client_id             = azuread_application.this.application_id
  auth_aad_tenant_auth_endpoint  = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  auth_aad_client_secret_setting_name = "AAD_CLIENT_SECRET"
  auth_aad_allowed_audiences     = ["api://myapp"]
  
  additional_app_settings = {
    "AAD_CLIENT_SECRET" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.aad_secret.id})"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| azurerm_service_plan | resource |
| azurerm_linux_web_app | resource |
| azurerm_linux_web_app_slot | resource |
| azurerm_private_endpoint | resource |
| azurerm_monitor_autoscale_setting | resource |
| azurerm_monitor_diagnostic_setting | resource |
| azurerm_monitor_metric_alert | resource |
| azurerm_app_service_custom_hostname_binding | resource |
| azurerm_app_service_certificate_binding | resource |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| project | Project name | `string` |
| app_name | Application name | `string` |
| environment | Environment (dev, qa, prod) | `string` |
| location | Azure region | `string` |
| location_short | Short name for Azure region | `string` |
| resource_group_name | Resource group name | `string` |

### App Service Plan Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_service_plan | Create new App Service Plan | `bool` | `true` |
| existing_service_plan_id | Existing plan ID | `string` | `null` |
| sku_name | App Service Plan SKU | `string` | `"B1"` |
| zone_redundant | Enable zone redundancy | `bool` | `false` |
| worker_count | Number of workers | `number` | `1` |

### Autoscaling Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_autoscale | Enable autoscaling | `bool` | `false` |
| autoscale_min_capacity | Minimum instances | `number` | `1` |
| autoscale_max_capacity | Maximum instances | `number` | `3` |
| autoscale_cpu_threshold_up | CPU % to scale up | `number` | `70` |
| autoscale_cpu_threshold_down | CPU % to scale down | `number` | `30` |

### Runtime Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| runtime_stack | Runtime (dotnet, node, python, java, ruby, php, go, docker) | `string` | `"dotnet"` |
| dotnet_version | .NET version | `string` | `"8.0"` |
| node_version | Node version | `string` | `"20-lts"` |
| python_version | Python version | `string` | `"3.12"` |

### Security Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| https_only | Require HTTPS | `bool` | `true` |
| minimum_tls_version | Minimum TLS version | `string` | `"1.2"` |
| client_certificate_enabled | Enable client certificates | `bool` | `false` |
| ftps_state | FTP/FTPS state | `string` | `"Disabled"` |

### Networking Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_vnet_integration | Enable VNet integration | `bool` | `true` |
| subnet_id | Subnet ID for integration | `string` | `null` |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` |
| private_endpoint_subnet_id | Subnet for private endpoint | `string` | `null` |
| ip_restrictions | IP restrictions list | `list(object)` | `[]` |

### Monitoring Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_diagnostics | Enable diagnostics | `bool` | `true` |
| enable_alerts | Enable metric alerts | `bool` | `false` |
| app_insights_connection_string | App Insights connection | `string` | `null` |
| log_analytics_workspace_id | Log Analytics workspace | `string` | `null` |

For a complete list of inputs, see [variables.tf](./variables.tf).

## Outputs

| Name | Description |
|------|-------------|
| app_service_id | The ID of the Linux Web App |
| app_service_name | The name of the Linux Web App |
| app_service_default_hostname | Default hostname |
| app_service_identity_principal_id | Managed identity principal ID |
| service_plan_id | App Service Plan ID |
| private_endpoint_id | Private endpoint ID |
| staging_slot_id | Staging slot ID |

For a complete list of outputs, see [outputs.tf](./outputs.tf).

## Best Practices

### Production Deployments

1. **Use Premium SKUs** (`P1V3` or higher) for zone redundancy and better performance
2. **Enable Private Endpoints** for secure inbound access
3. **Enable VNet Integration** for secure outbound access
4. **Use Always On** to keep apps warm
5. **Enable Autoscaling** to handle load variations
6. **Configure Health Checks** for automatic recovery
7. **Enable Backup** for disaster recovery
8. **Use Deployment Slots** for zero-downtime deployments

### Security Recommendations

1. **Use Managed Identity** instead of connection strings
2. **Store secrets in Key Vault** and reference them in app settings
3. **Disable FTP/FTPS** completely
4. **Enable TLS 1.2 minimum**
5. **Configure IP restrictions** to limit access
6. **Enable Azure AD authentication** for user-facing apps
7. **Enable diagnostic logging** for security monitoring

### Cost Optimization

1. **Use autoscaling** instead of over-provisioning
2. **Share App Service Plans** for multiple apps when appropriate
3. **Use B-series SKUs** for dev/test environments
4. **Enable zone redundancy** only in production
5. **Configure appropriate backup retention** periods

## Examples by Scenario

### Microservices API
- Premium SKU with autoscaling
- Private endpoint + VNet integration
- Health checks and auto-heal
- Application Insights monitoring

### Public Website
- Standard SKU with always on
- Custom domain with SSL
- Azure CDN integration via Front Door
- Deployment slots for staging

### Background Worker
- Basic SKU (no always on needed)
- VNet integration only
- Shared App Service Plan
- Minimal logging

### Container-based Application
- Docker runtime stack
- Managed identity for ACR
- VNet integration for data access
- Health checks on custom endpoint

## Troubleshooting

### App doesn't start
- Check runtime stack version compatibility
- Verify managed identity has required permissions
- Review Application Insights logs
- Check health check endpoint

### Network connectivity issues
- Verify VNet integration subnet has delegation
- Check NSG rules on subnets
- Verify private endpoint DNS resolution
- Review IP restrictions configuration

### Performance issues
- Enable Always On for production
- Check App Service Plan sizing
- Review autoscaling configuration
- Analyze Application Insights metrics

## Migration Guide

### From Basic to Robust Module

If migrating from a simpler module:

1. Add identity configuration
2. Configure networking (VNet integration, private endpoints)
3. Enable monitoring and alerts
4. Add autoscaling rules
5. Configure backup
6. Test with deployment slots

## Contributing

When contributing to this module:

1. Follow Terraform best practices
2. Update examples for new features
3. Add appropriate validation rules
4. Update README documentation
5. Test in dev environment first

## License

This module is part of the EVO-TASKERS-TF project.

## Support

For issues or questions:
1. Check troubleshooting section
2. Review Azure documentation
3. Check Terraform AzureRM provider docs
4. Contact the platform team

## Changelog

### Version 2.0 (Current)
- Complete rewrite for robustness
- Added autoscaling support
- Added deployment slots
- Enhanced monitoring and alerting
- Added authentication support
- Added backup configuration
- Added custom domain support
- Flexible identity management
- IP restriction support
- Auto-heal capabilities
- Storage account mounting
- Enhanced logging options

### Version 1.0
- Initial basic implementation
