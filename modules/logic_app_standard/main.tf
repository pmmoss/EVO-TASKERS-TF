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

module "naming_la" {
  source         = "../naming"
  resource_type  = "la"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

# App Service Plan for Logic App Standard (Workflow Standard SKU)
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

# Logic App Standard
resource "azurerm_logic_app_standard" "this" {
  name                       = "${module.naming_la.name}-${var.app_name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_service_plan.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  storage_account_share_name = var.storage_account_share_name
  
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
      "APPINSIGHTS_INSTRUMENTATIONKEY" = var.app_insights_instrumentation_key
      
      # Managed Identity
      "AZURE_CLIENT_ID" = var.user_assigned_identity_client_id
      
      # Logic App settings
      "FUNCTIONS_WORKER_RUNTIME" = "node"
      "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
      "FUNCTIONS_EXTENSION_VERSION" = "~4"
      "WEBSITE_CONTENTOVERVNET" = "1"
      
      # Key Vault reference for secrets (use managed identity)
      "KeyVaultUri" = var.key_vault_uri
      
      # Workflows Runtime Settings
      "AzureWebJobsStorage" = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${var.storage_account_access_key};EndpointSuffix=core.windows.net"
      "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${var.storage_account_access_key};EndpointSuffix=core.windows.net"
      "WEBSITE_CONTENTSHARE" = var.storage_account_share_name
    },
    var.additional_app_settings
  )

  site_config {
    # Always on (required for Logic App Standard)
    always_on = true
    
    # FTPs state - disable FTP, allow FTPS only
    ftps_state = "Disabled"
    
    # Runtime scale monitoring
    runtime_scale_monitoring_enabled = true
    
    # Extension bundle configuration (for built-in connectors)
    dynamic "app_service_logs" {
      for_each = var.enable_diagnostics ? [1] : []
      content {
        disk_quota_mb         = 35
        retention_period_days = 7
      }
    }
  }

  # Use extension bundle if enabled - configured via app settings
  # The bundle configuration is handled through FUNCTIONS_EXTENSION_VERSION
  # and additional workflow-specific settings in app_settings

  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      # Ignore changes to app settings that might be set by deployment pipelines
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Private Endpoint for Logic App (optional, recommended for production)
resource "azurerm_private_endpoint" "logic_app" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${var.app_name}-${module.naming_la.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming_la.name}"
    private_connection_resource_id = azurerm_logic_app_standard.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

# Diagnostic Settings (if enabled)
resource "azurerm_monitor_diagnostic_setting" "logic_app" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag-${module.naming_la.name}"
  target_resource_id         = azurerm_logic_app_standard.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "WorkflowRuntime"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

