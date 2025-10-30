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

module "naming_fa" {
  source         = "../naming"
  resource_type  = "fa"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

module "naming_pe" {
  source         = "../naming"
  resource_type  = "pe"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}
# App Service Plan for Linux Function Apps (separate from Web App plan)
resource "azurerm_service_plan" "this" {
  name                = "${module.naming_asp.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.sku_name
  
  tags = merge(var.tags, {
    Application = var.app_name
  })
}

# Windows Function App
resource "azurerm_windows_function_app" "this" {
  name                       = "${module.naming_fa.name}-${var.app_name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  # Enable HTTPS only (secure by default)
  https_only = true
  
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
      
      # Function App settings
      "FUNCTIONS_WORKER_RUNTIME" = var.functions_worker_runtime
      "FUNCTIONS_EXTENSION_VERSION" = "~4"
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
    
    # Always on (if supported by SKU)
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
    
    # Runtime version - conditionally set based on worker runtime
    application_stack {
      dotnet_version  = var.functions_worker_runtime == "dotnet" ? var.dotnet_version : null
      node_version    = var.functions_worker_runtime == "node" ? var.node_version : null
      //python_version  = var.functions_worker_runtime == "python" ? var.python_version : null
      java_version    = var.functions_worker_runtime == "java" ? var.java_version : null
    }
  }

  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to app settings that might be set by Azure DevOps
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Private Endpoint for Function App (optional, recommended for production)
resource "azurerm_private_endpoint" "function_app" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${module.naming_pe.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming_fa.name}-${var.app_name}"
    private_connection_resource_id = azurerm_windows_function_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

# Diagnostic Settings (if enabled)
resource "azurerm_monitor_diagnostic_setting" "function_app" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag-${module.naming_fa.name}"
  target_resource_id         = azurerm_windows_function_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

