terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Naming for resources
module "naming_asp" {
  source         = "../naming"
  resource_type  = "asp"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

module "naming_app" {
  source         = "../naming"
  resource_type  = "app"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

# App Service Plan for Linux (separate from Function App plan)
resource "azurerm_service_plan" "this" {
  name                = "${module.naming_asp.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  
  tags = merge(var.tags, {
    Application = var.app_name
  })
}

# Linux Web App
resource "azurerm_linux_web_app" "this" {
  name                       = "${module.naming_app.name}-${var.app_name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.this.id
  
  # Enable HTTPS only (secure by default)
  https_only = true
  
  # Disable public network access if private endpoint is enabled
  public_network_access_enabled = !var.enable_private_endpoint
  
  # Enable VNet integration for outbound traffic
  virtual_network_subnet_id = var.enable_vnet_integration ? var.subnet_id : null

  # User-assigned managed identity
  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  # Application settings
  app_settings = merge(
    {
      # Application Insights
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
      "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
      
      # Managed Identity
      "AZURE_CLIENT_ID" = var.user_assigned_identity_client_id
      
      # App settings
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
      "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
      
      # Key Vault reference for secrets (use managed identity)
      "KeyVaultUri" = var.key_vault_uri
    },
    var.additional_app_settings
  )

  site_config {
    # Minimum TLS version
    minimum_tls_version = "1.2"
    
    # Always on
    always_on = var.always_on
    
    # FTPs state - disable FTP, allow FTPS only
    ftps_state = "Disabled"
    
    # HTTP2 enabled
    http2_enabled = true
    
    # Use 32-bit worker process (set to false for production workloads)
    use_32_bit_worker = false
    
    # CORS settings (only enabled if origins are specified)
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = false
      }
    }
    
    # Runtime stack - conditionally set based on var.runtime_stack
    application_stack {
      dotnet_version      = var.runtime_stack == "dotnet" ? var.dotnet_version : null
      node_version        = var.runtime_stack == "node" ? var.node_version : null
      python_version      = var.runtime_stack == "python" ? var.python_version : null
      java_server         = var.runtime_stack == "java" ? var.java_server : null
      java_version        = var.runtime_stack == "java" ? var.java_version : null
      java_server_version = var.runtime_stack == "java" ? var.java_server_version : null
    }
    
    # Health check path
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time
  }

  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to app settings that might be set by Azure DevOps
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Private Endpoint for App Service (optional, recommended for production)
resource "azurerm_private_endpoint" "app_service" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${module.naming_app.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming_app.name}"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

# Diagnostic Settings (if enabled)
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag-${module.naming_app.name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

