# Logic App Standard for UnlockBookings workflows
# Deploys a Logic App Standard with connected identity, storage, and app settings.

module "logic_app_standard" {
  source = "../../../modules/logic_app_standard"
  
  # Application identifier
  app_name = "${var.app_name}-workflow"
  
  # Project configuration from common infrastructure
  project        = local.project
  environment    = local.environment
  location       = local.location
  location_short = local.location_short
  
  # Resource group from common infrastructure
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  # SKU configuration (WS1, WS2, WS3 for Workflow Standard)
  sku_name = var.logic_app_sku
  
  # Storage account (required for Logic App Standard)
  storage_account_name       = data.terraform_remote_state.common.outputs.storage_account_name
  storage_account_access_key = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
  storage_account_share_name = var.logic_app_storage_share_name
  
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
  
  # Extension bundle configuration
  use_extension_bundle = var.use_extension_bundle
  bundle_version      = var.bundle_version
  
  # Additional app settings for workflows
  additional_app_settings = merge(
    var.additional_logic_app_settings,
    {
      "ApplicationName" = "UnlockBookings-Workflow"
      "Workflow.Environment" = var.environment
    }
  )
  
  tags = local.tags
}

