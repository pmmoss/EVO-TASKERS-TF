# Windows Function App for SendGridFunction
# Using Azure Verified Module (AVM) - secure by default

module "windows_function_app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.19"
  
  # Core configuration
  name                     = "${local.project}-${var.app_name}-${local.environment}-${local.location_short}"
  resource_group_name      = data.terraform_remote_state.common.outputs.resource_group_name
  location                 = local.location
  kind                     = "functionapp"
  os_type                  = "Windows"
  service_plan_resource_id = data.terraform_remote_state.common.outputs.windows_function_plan_id
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Storage account configuration (required for Function Apps)
  storage_account_name       = data.terraform_remote_state.common.outputs.storage_account_name
  storage_account_access_key = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
  
  # Managed Identity configuration
  managed_identities = {
    user_assigned_resource_ids = [
      data.terraform_remote_state.common.outputs.workload_identity_id
    ]
  }
  
  # Application Insights configuration
  enable_application_insights = false # Using existing App Insights from common
  
  # App Settings including Application Insights
  app_settings = merge(
    var.additional_function_app_settings,
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
      "ApplicationName" = "SendGridFunction"
      "Workspace"       = terraform.workspace
    }
  )
  
  # Site configuration - secure by default
  site_config = {
    # Always on - supported by shared EP1 plan
    always_on = true
    
    # Security settings (AVM defaults are secure)
    minimum_tls_version = "1.3"
    ftps_state          = "Disabled"
    http2_enabled       = true
    
    # Application stack
    application_stack = {
      dotnet = {
        dotnet_version              = var.dotnet_version
        use_dotnet_isolated_runtime = true
      }
    }
    
    # VNet integration for outbound traffic
    vnet_route_all_enabled = true
  }
  
  # VNet integration for outbound traffic
  virtual_network_subnet_id = data.terraform_remote_state.common.outputs.app_integration_subnet_id
  
  # Private endpoint for inbound traffic (conditional based on environment)
  private_endpoints = var.enable_private_endpoint ? {
    primary = {
      name                          = "${local.project}-${var.app_name}-${local.environment}-pe"
      subnet_resource_id            = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings
  diagnostic_settings = {
    function_app_diagnostics = {
      name                  = "diag-${local.project}-${var.app_name}-${local.environment}"
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

