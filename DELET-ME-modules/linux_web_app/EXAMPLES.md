# Linux Web App Module - Usage Examples

This document provides comprehensive examples for common use cases of the Linux Web App module.

## Table of Contents

1. [Basic Development App](#basic-development-app)
2. [Production .NET Application](#production-net-application)
3. [Node.js API with Autoscaling](#nodejs-api-with-autoscaling)
4. [Python App with Azure AD Auth](#python-app-with-azure-ad-auth)
5. [Container-Based Application](#container-based-application)
6. [Multi-Tenant SaaS Application](#multi-tenant-saas-application)
7. [Microservices with Private Networking](#microservices-with-private-networking)
8. [Blue-Green Deployment Setup](#blue-green-deployment-setup)

---

## Basic Development App

Simple setup for development environment with minimal features.

```hcl
module "dev_web_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "api"
  environment    = "dev"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.dev.name
  
  # Basic SKU for development
  sku_name = "B1"
  
  # Runtime
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Simple identity
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Basic networking - public access
  enable_vnet_integration = false
  enable_private_endpoint = false
  public_network_access_enabled = true
  
  # Development settings
  always_on = false  # Save costs in dev
  
  # Minimal monitoring
  enable_diagnostics = false
  enable_alerts      = false
  
  # Development app settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Development"
    "ASPNETCORE_DETAILEDERRORS" = "true"
  }
  
  tags = {
    Environment = "Development"
    CostCenter  = "Engineering"
  }
}
```

---

## Production .NET Application

Full-featured production setup with high availability and security.

```hcl
# Data sources
data "azurerm_client_config" "current" {}

# User-assigned identity
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-myapp-prod"
  location            = "East US"
  resource_group_name = azurerm_resource_group.prod.name
}

# Key Vault access for the identity
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.prod.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id
  
  secret_permissions = ["Get", "List"]
}

# Production Web App
module "prod_web_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "api"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # Premium SKU with zone redundancy
  sku_name       = "P1V3"
  zone_redundant = true
  worker_count   = 3
  
  # Autoscaling for production load
  enable_autoscale           = true
  autoscale_min_capacity     = 3
  autoscale_max_capacity     = 10
  autoscale_default_capacity = 3
  autoscale_cpu_threshold_up   = 70
  autoscale_cpu_threshold_down = 25
  autoscale_memory_threshold_up = 80
  
  # Runtime
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Hybrid identity (system + user assigned)
  identity_type                    = "SystemAssigned, UserAssigned"
  user_assigned_identity_ids       = [azurerm_user_assigned_identity.app.id]
  user_assigned_identity_client_id = azurerm_user_assigned_identity.app.client_id
  key_vault_reference_identity_id  = azurerm_user_assigned_identity.app.id
  
  # Secure networking
  https_only                    = true
  public_network_access_enabled = false
  enable_vnet_integration       = true
  subnet_id                     = azurerm_subnet.app_integration.id
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.private_endpoints.id
  
  # IP restrictions (only allow traffic from Azure Front Door)
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
  
  # Security settings
  client_certificate_enabled = false
  client_certificate_mode    = "Optional"
  minimum_tls_version        = "1.2"
  ftps_state                 = "Disabled"
  
  # Performance settings
  always_on         = true
  http2_enabled     = true
  use_32_bit_worker = false
  
  # Health monitoring
  health_check_path          = "/health"
  health_check_eviction_time = 5
  
  # Auto-heal configuration
  enable_auto_heal                         = true
  auto_heal_action_type                    = "Recycle"
  auto_heal_trigger_requests_count         = 100
  auto_heal_trigger_requests_interval      = "00:01:00"
  auto_heal_minimum_process_execution_time = "00:01:00"
  auto_heal_trigger_status_codes = [
    {
      count             = 10
      interval          = "00:01:00"
      status_code_range = "500-599"
    }
  ]
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  key_vault_uri                  = azurerm_key_vault.prod.vault_uri
  
  # Comprehensive diagnostics
  enable_diagnostics         = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id
  diagnostic_log_categories = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceAuditLogs",
    "AppServicePlatformLogs",
    "AppServiceIPSecAuditLogs"
  ]
  
  # Alerting
  enable_alerts                 = true
  alert_action_group_id         = azurerm_monitor_action_group.prod.id
  alert_cpu_threshold           = 80
  alert_memory_threshold        = 85
  alert_response_time_threshold = 5
  alert_http_errors_threshold   = 10
  
  # Backup configuration
  enable_backup                = true
  backup_storage_account_url   = "${azurerm_storage_account.backup.primary_blob_endpoint}${azurerm_storage_container.backup.name}${data.azurerm_storage_account_sas.backup.sas}"
  backup_frequency_interval    = 1
  backup_frequency_unit        = "Day"
  backup_retention_period_days = 30
  backup_start_time            = "2024-01-01T02:00:00Z"
  
  # Deployment slot for zero-downtime deployments
  create_staging_slot = true
  staging_slot_name   = "staging"
  
  # Production app settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT"           = "Production"
    "ASPNETCORE_FORWARDEDHEADERS_ENABLED" = "true"
  }
  
  # Connection strings from Key Vault
  connection_strings = [
    {
      name  = "DefaultConnection"
      type  = "SQLAzure"
      value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection.id})"
    }
  ]
  
  # Settings that should stick to deployment slot
  sticky_app_setting_names = [
    "ASPNETCORE_ENVIRONMENT"
  ]
  
  tags = {
    Environment = "Production"
    CostCenter  = "Engineering"
    Criticality = "High"
  }
}

# Output important values
output "app_url" {
  value = "https://${module.prod_web_app.app_service_default_hostname}"
}

output "app_principal_id" {
  value = module.prod_web_app.app_service_identity_principal_id
}
```

---

## Node.js API with Autoscaling

Node.js application with aggressive autoscaling for variable workloads.

```hcl
module "nodejs_api" {
  source = "../../../../modules/linux_web_app"
  
  project        = "ecommerce"
  app_name       = "api"
  environment    = "prod"
  location       = "West Europe"
  location_short = "weu"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # Standard SKU for cost optimization
  sku_name = "S2"
  
  # Aggressive autoscaling for traffic spikes
  enable_autoscale           = true
  autoscale_min_capacity     = 2
  autoscale_max_capacity     = 15
  autoscale_default_capacity = 2
  autoscale_cpu_threshold_up   = 60  # Scale up faster
  autoscale_cpu_threshold_down = 20  # Scale down slower
  autoscale_memory_threshold_up = 75
  
  # Node.js runtime
  runtime_stack = "node"
  node_version  = "20-lts"
  
  # Identity
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = azurerm_subnet.app_integration.id
  
  # Performance
  always_on          = true
  websockets_enabled = true  # Enable for real-time features
  http2_enabled      = true
  
  # CORS for frontend
  cors_allowed_origins = [
    "https://shop.example.com",
    "https://admin.example.com"
  ]
  cors_support_credentials = true
  
  # Health check
  health_check_path          = "/api/health"
  health_check_eviction_time = 3
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  enable_diagnostics             = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.prod.id
  
  # Node-specific settings
  additional_app_settings = {
    "NODE_ENV"              = "production"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~20"
    "NPM_CONFIG_PRODUCTION" = "true"
  }
  
  tags = {
    Application = "E-commerce API"
    Environment = "Production"
  }
}
```

---

## Python App with Azure AD Auth

Python web application with Azure AD authentication.

```hcl
# Azure AD App Registration (create this separately)
data "azuread_application" "app" {
  display_name = "MyPythonApp"
}

module "python_web_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "portal"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # App Service Plan
  sku_name = "P1V2"
  
  # Python runtime
  runtime_stack  = "python"
  python_version = "3.12"
  
  # Identity
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = azurerm_subnet.app_integration.id
  
  # Azure AD Authentication
  enable_auth                   = true
  auth_require_authentication   = true
  auth_unauthenticated_action   = "RedirectToLoginPage"
  auth_default_provider         = "AzureActiveDirectory"
  auth_runtime_version          = "~1"
  
  auth_login_enabled            = true
  auth_token_store_enabled      = true
  auth_token_refresh_extension_hours = 72
  
  auth_active_directory_enabled = true
  auth_aad_client_id            = data.azuread_application.app.application_id
  auth_aad_tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
  auth_aad_client_secret_setting_name = "AAD_CLIENT_SECRET"
  auth_aad_allowed_audiences    = [
    "api://${data.azuread_application.app.application_id}"
  ]
  
  # Python-specific settings
  additional_app_settings = {
    "FLASK_ENV"              = "production"
    "PYTHONPATH"             = "/home/site/wwwroot"
    "AAD_CLIENT_SECRET"      = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.aad_secret.id})"
  }
  
  # Startup command for Python app
  run_from_package = "1"
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  enable_diagnostics             = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.prod.id
  
  tags = {
    Application = "Internal Portal"
    Environment = "Production"
  }
}
```

---

## Container-Based Application

Docker container deployment with Azure Container Registry.

```hcl
# Container registry
resource "azurerm_container_registry" "acr" {
  name                = "myappsacr"
  resource_group_name = azurerm_resource_group.prod.name
  location            = azurerm_resource_group.prod.location
  sku                 = "Premium"
  admin_enabled       = false
}

# User-assigned identity for ACR access
resource "azurerm_user_assigned_identity" "acr" {
  name                = "id-acr-pull"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
}

# Grant ACR pull permissions
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr.principal_id
}

module "container_web_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "containerapp"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # App Service Plan
  sku_name = "P1V3"
  
  # Docker runtime
  runtime_stack       = "docker"
  docker_image_name   = "myapp:latest"
  docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
  
  # Use managed identity for ACR authentication (no passwords!)
  container_registry_use_managed_identity       = true
  container_registry_managed_identity_client_id = azurerm_user_assigned_identity.acr.client_id
  
  # Identity
  identity_type              = "UserAssigned"
  user_assigned_identity_ids = [azurerm_user_assigned_identity.acr.id]
  user_assigned_identity_client_id = azurerm_user_assigned_identity.acr.client_id
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = azurerm_subnet.app_integration.id
  
  # Container-specific settings
  additional_app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_ENABLE_CI"                = "true"
    "WEBSITES_PORT"                   = "8080"  # Container port
  }
  
  # Health check on custom port
  health_check_path          = "/healthz"
  health_check_eviction_time = 5
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  
  tags = {
    Application = "Container App"
    Environment = "Production"
  }
  
  depends_on = [azurerm_role_assignment.acr_pull]
}
```

---

## Multi-Tenant SaaS Application

Multi-tenant application with backup and disaster recovery.

```hcl
# Storage account for backups
resource "azurerm_storage_account" "backup" {
  name                     = "sabackupmyapp"
  resource_group_name      = azurerm_resource_group.prod.name
  location                 = azurerm_resource_group.prod.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "backup" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.backup.name
  container_access_type = "private"
}

# SAS token for backup access
data "azurerm_storage_account_sas" "backup" {
  connection_string = azurerm_storage_account.backup.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"
  
  resource_types {
    service   = true
    container = true
    object    = true
  }
  
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  
  start  = "2024-01-01T00:00:00Z"
  expiry = "2025-12-31T23:59:59Z"
  
  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = false
    tag     = false
    filter  = false
  }
}

module "saas_web_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "saasapp"
  app_name       = "platform"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # Premium SKU with zone redundancy for HA
  sku_name       = "P2V3"
  zone_redundant = true
  worker_count   = 3
  
  # Autoscaling for multi-tenant load
  enable_autoscale           = true
  autoscale_min_capacity     = 3
  autoscale_max_capacity     = 20
  autoscale_default_capacity = 5
  
  # Runtime
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Identity
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Secure networking
  enable_vnet_integration       = true
  subnet_id                     = azurerm_subnet.app_integration.id
  enable_private_endpoint       = false  # Public SaaS
  public_network_access_enabled = true
  
  # IP restrictions for admin endpoints
  ip_restrictions = [
    {
      name       = "AllowAll"
      ip_address = "0.0.0.0/0"
      priority   = 65000
      action     = "Allow"
    }
  ]
  
  scm_ip_restrictions = [
    {
      name       = "AllowOfficeIP"
      ip_address = "203.0.113.0/24"  # Your office IP
      priority   = 100
      action     = "Allow"
    }
  ]
  
  # Performance
  always_on         = true
  http2_enabled     = true
  load_balancing_mode = "LeastResponseTime"
  
  # Health and recovery
  health_check_path          = "/health"
  health_check_eviction_time = 10
  
  enable_auto_heal                         = true
  auto_heal_action_type                    = "Recycle"
  auto_heal_trigger_requests_count         = 200
  auto_heal_trigger_requests_interval      = "00:05:00"
  auto_heal_minimum_process_execution_time = "00:02:00"
  
  # Comprehensive monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  enable_diagnostics             = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.prod.id
  
  # Alerting
  enable_alerts                 = true
  alert_action_group_id         = azurerm_monitor_action_group.prod.id
  alert_cpu_threshold           = 75
  alert_memory_threshold        = 80
  alert_response_time_threshold = 3
  alert_http_errors_threshold   = 20
  
  # Daily backups with 30-day retention
  enable_backup                = true
  backup_storage_account_url   = "${azurerm_storage_account.backup.primary_blob_endpoint}${azurerm_storage_container.backup.name}${data.azurerm_storage_account_sas.backup.sas}"
  backup_frequency_interval    = 1
  backup_frequency_unit        = "Day"
  backup_keep_at_least_one     = true
  backup_retention_period_days = 30
  backup_start_time            = "2024-01-01T03:00:00Z"
  
  # Deployment slot for safe rollouts
  create_staging_slot = true
  staging_slot_name   = "staging"
  
  # SaaS app settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT"    = "Production"
    "MultiTenant__Enabled"      = "true"
    "FeatureManagement__Premium" = "true"
  }
  
  tags = {
    Application = "SaaS Platform"
    Environment = "Production"
    Tier        = "Premium"
  }
}
```

---

## Microservices with Private Networking

Microservice accessible only through private network.

```hcl
module "private_microservice" {
  source = "../../../../modules/linux_web_app"
  
  project        = "microservices"
  app_name       = "order-service"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # Standard SKU sufficient for internal service
  sku_name = "S2"
  
  # Runtime
  runtime_stack  = "dotnet"
  dotnet_version = "8.0"
  
  # Identity for service-to-service auth
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Private networking only
  https_only                    = true
  public_network_access_enabled = false  # No public access
  enable_vnet_integration       = true
  subnet_id                     = azurerm_subnet.microservices_integration.id
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.private_endpoints.id
  
  # Only allow traffic from other services in VNet
  ip_restrictions = [
    {
      name                      = "AllowInternalVNet"
      virtual_network_subnet_id = azurerm_subnet.microservices_integration.id
      priority                  = 100
      action                    = "Allow"
    }
  ]
  
  # Performance
  always_on = true
  
  # Service health endpoint
  health_check_path          = "/health"
  health_check_eviction_time = 3
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  enable_diagnostics             = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.prod.id
  
  # Microservice settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "ServiceBus__ConnectionString" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.servicebus.id})"
  }
  
  tags = {
    Application = "Order Service"
    Tier        = "Microservice"
  }
}

# Private DNS zone for private endpoint
resource "azurerm_private_dns_zone" "app_service" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.prod.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app_service" {
  name                  = "vnet-link"
  resource_group_name   = azurerm_resource_group.prod.name
  private_dns_zone_name = azurerm_private_dns_zone.app_service.name
  virtual_network_id    = azurerm_virtual_network.prod.id
}
```

---

## Blue-Green Deployment Setup

Application configured for blue-green deployments using slots.

```hcl
module "blue_green_app" {
  source = "../../../../modules/linux_web_app"
  
  project        = "myproject"
  app_name       = "webapp"
  environment    = "prod"
  location       = "East US"
  location_short = "eus"
  
  resource_group_name = azurerm_resource_group.prod.name
  
  # App Service Plan
  sku_name = "P1V3"
  
  # Runtime
  runtime_stack  = "node"
  node_version   = "20-lts"
  
  # Identity
  identity_type              = "SystemAssigned"
  user_assigned_identity_ids = []
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = azurerm_subnet.app_integration.id
  
  # Enable staging slot for blue-green
  create_staging_slot = true
  staging_slot_name   = "green"  # Production is "blue", slot is "green"
  
  # Different settings for green slot
  staging_slot_app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Staging"
    "SLOT_NAME"              = "green"
  }
  
  # Production (blue) settings
  additional_app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "SLOT_NAME"              = "blue"
  }
  
  # Settings that change per slot (not swapped)
  sticky_app_setting_names = [
    "ASPNETCORE_ENVIRONMENT",
    "SLOT_NAME"
  ]
  
  # Health check for both slots
  health_check_path          = "/health"
  health_check_eviction_time = 5
  
  # Monitoring
  app_insights_connection_string = azurerm_application_insights.prod.connection_string
  
  tags = {
    Application     = "Web App"
    DeploymentStyle = "BlueGreen"
  }
}

# After validation in green slot, swap using Azure CLI or Portal:
# az webapp deployment slot swap --resource-group <rg> --name <app> --slot green --target-slot production
```

---

## Notes

- All examples assume you have the necessary Azure resources (resource groups, VNets, subnets, etc.) already created
- Adjust SKUs based on your actual workload requirements
- Always test in non-production environments first
- Consider cost implications of premium features like zone redundancy and autoscaling
- Follow the principle of least privilege when assigning permissions to managed identities

