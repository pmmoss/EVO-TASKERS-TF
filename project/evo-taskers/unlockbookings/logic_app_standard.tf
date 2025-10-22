# Logic App Standard for UnlockBookings workflows
# Using Azure Verified Module (AVM) - secure by default

module "logic_app_standard" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.19"
  
  # Core configuration - Logic App is a special kind of web site
  name                     = "${local.project}-${var.app_name}-workflow-${local.environment}-${local.location_short}"
  resource_group_name      = data.terraform_remote_state.common.outputs.resource_group_name
  location                 = local.location
  kind                     = "logicapp"  # Logic App Standard
  os_type                  = "Windows"   # Logic App Standard uses Windows
  service_plan_resource_id = data.terraform_remote_state.common.outputs.logic_app_plan_id
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Storage account configuration (required for Logic App Standard)
  storage_account_name         = data.terraform_remote_state.common.outputs.storage_account_name
  storage_account_access_key   = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
  storage_account_share_name   = var.logic_app_storage_share_name
  
  # Managed Identity configuration
  managed_identities = {
    user_assigned_resource_ids = [
      data.terraform_remote_state.common.outputs.workload_identity_id
    ]
  }
  
  # Application Insights configuration
  enable_application_insights = false # Using existing App Insights from common
  
  # Logic App specific settings
  use_extension_bundle  = var.use_extension_bundle
  bundle_version        = var.bundle_version
  
  # App Settings including Application Insights
  app_settings = merge(
    var.additional_logic_app_settings,
    {
      # Application Insights
      "APPLICATIONINSIGHTS_CONNECTION_STRING"        = data.terraform_remote_state.common.outputs.app_insights_connection_string
      "ApplicationInsightsAgent_EXTENSION_VERSION"   = "~3"
      "APPINSIGHTS_INSTRUMENTATIONKEY"               = data.terraform_remote_state.common.outputs.app_insights_instrumentation_key
      
      # Managed Identity
      "AZURE_CLIENT_ID" = data.terraform_remote_state.common.outputs.workload_identity_client_id
      
      # Key Vault reference
      "KeyVaultUri" = data.terraform_remote_state.common.outputs.key_vault_uri
      
      # Application metadata
      "ApplicationName"       = "UnlockBookings-Workflow"
      "Workflow.Environment" = var.environment
    }
  )
  
  # Site configuration - secure by default
  site_config = {
    # Always on - supported by WS1 plan
    always_on = true
    
    # Security settings (AVM defaults are secure)
    minimum_tls_version = "1.3"
    ftps_state          = "Disabled"
    http2_enabled       = true
    
    # Logic Apps don't need application_stack configuration
    
    # VNet integration for outbound traffic
    vnet_route_all_enabled = true
  }
  
  # VNet integration for outbound traffic
  virtual_network_subnet_id = data.terraform_remote_state.common.outputs.app_integration_subnet_id
  
  # Private endpoint for inbound traffic (conditional based on environment)
  private_endpoints = var.enable_private_endpoint ? {
    primary = {
      name                          = "${local.project}-${var.app_name}-workflow-${local.environment}-pe"
      subnet_resource_id            = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings
  diagnostic_settings = {
    logic_app_diagnostics = {
      name                  = "diag-${local.project}-${var.app_name}-workflow-${local.environment}"
      workspace_resource_id = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }
  
  # HTTPS only (secure by default)
  https_only = true
  
  # Tags
  tags = local.tags
}

