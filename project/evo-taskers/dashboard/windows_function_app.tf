# Windows Function App for Dashboard

module "windows_function_app" {
  source = "../../../modules/windows_function_app"
  
  # Application identifier
  app_name = var.app_name
  
  # Project configuration from common infrastructure
  project        = local.project
  environment    = local.environment
  location       = local.location
  location_short = local.location_short
  
  # Resource group from common infrastructure
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  # App Service Plan - Use shared Windows Function plan from shared services
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.shared.outputs.windows_function_plan_id
  
  # Always on - depends on the shared plan SKU
  always_on = true  # Shared EP1 plan supports always_on
  
  # Storage account (required for Function Apps)
  storage_account_name       = data.terraform_remote_state.common.outputs.storage_account_name
  storage_account_access_key = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
  
  # Managed Identity from common infrastructure
  user_assigned_identity_id        = data.terraform_remote_state.common.outputs.workload_identity_id
  user_assigned_identity_client_id = data.terraform_remote_state.common.outputs.workload_identity_client_id
  
  # Networking - VNet integration for outbound traffic
  enable_vnet_integration = true
  subnet_id              = data.terraform_remote_state.common.outputs.app_integration_subnet_id
  
  # Private endpoint for inbound traffic (optional, recommended for production)
  enable_private_endpoint    = var.enable_private_endpoint
  private_endpoint_subnet_id = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
  
  # Monitoring
  app_insights_connection_string   = data.terraform_remote_state.common.outputs.app_insights_connection_string
  app_insights_instrumentation_key = data.terraform_remote_state.common.outputs.app_insights_instrumentation_key
  log_analytics_workspace_id       = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
  enable_diagnostics              = true
  
  # Key Vault
  key_vault_uri = data.terraform_remote_state.common.outputs.key_vault_uri
  
  # Function runtime configuration
  functions_worker_runtime = var.functions_worker_runtime
  dotnet_version          = var.dotnet_version
  
  # Additional app settings
  additional_app_settings = merge(
    var.additional_function_app_settings,
    {
      "ApplicationName" = "Dashboard"
      "Workspace"       = terraform.workspace
    }
  )
  
  tags = local.tags
}

