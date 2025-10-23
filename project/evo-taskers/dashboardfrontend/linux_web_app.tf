# Linux Web App for DashboardFrontend
# Using Azure Verified Module (AVM) - secure by default

module "linux_web_app" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "~> 0.19.1"

  # Core configuration
  name                     = "${local.project}-${var.app_name}-${local.environment}-${local.location_short}"
  resource_group_name      = data.terraform_remote_state.common.outputs.resource_group_name
  location                 = local.location
  kind                     = "app"
  os_type                  = "Linux"
  service_plan_resource_id = data.terraform_remote_state.common.outputs.linux_web_plan_id

  # Enable telemetry for AVM (recommended)
  enable_telemetry = true

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
    var.additional_app_settings,
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
      "ApplicationName" = "DashboardFrontend"
      "Workspace"       = terraform.workspace
      "Environment"     = local.environment
    }
  )

  # Site configuration - secure by default
  site_config = {
    # Always on - supported by shared plan
    always_on = var.app_service_always_on

    # Security settings (AVM defaults are secure)
    minimum_tls_version = var.minimum_tls_version
    ftps_state          = var.ftps_state
    http2_enabled       = var.http2_enabled

    # Application stack based on runtime
    application_stack = var.runtime_stack == "dotnet" ? {
      dotnet = {
        dotnet_version = var.dotnet_version
      }
    } : var.runtime_stack == "node" ? {
      node = {
        node_version = var.node_version
      }
    } : var.runtime_stack == "python" ? {
      python = {
        python_version = var.python_version
      }
    } : {}

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
    web_app_diagnostics = {
      name                  = "diag-${local.project}-${var.app_name}-${local.environment}"
      workspace_resource_id = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  }

  # HTTPS only (secure by default)
  https_only = var.https_only

  # Tags
  tags = local.tags
}
