# App Service for UnlockBookings API
# UnlockBookings uses Function App only - App Service not needed

# module "app_service" {
#   source = "../../../../modules/app_service"
#   
#   # Application identifier
#   app_name = "unlockbookings"
#   
#   # Project configuration from common infrastructure
#   project        = local.project
#   environment    = local.environment
#   location       = local.location
#   location_short = local.location_short
#   
#   # Resource group
#   resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
#   
#   # SKU configuration
#   sku_name  = var.app_service_sku
#   always_on = var.app_service_always_on
#   
#   # Managed Identity from common infrastructure
#   user_assigned_identity_id        = data.terraform_remote_state.common.outputs.workload_identity_id
#   user_assigned_identity_client_id = data.terraform_remote_state.common.outputs.workload_identity_client_id
#   
#   # Networking - VNet integration for outbound traffic
#   enable_vnet_integration = true
#   subnet_id              = data.terraform_remote_state.common.outputs.app_integration_subnet_id
#   
#   # Private endpoint for inbound traffic (optional, recommended for production)
#   enable_private_endpoint    = var.enable_private_endpoint
#   private_endpoint_subnet_id = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
#   
#   # Monitoring
#   app_insights_connection_string   = data.terraform_remote_state.common.outputs.app_insights_connection_string
#   app_insights_instrumentation_key = data.terraform_remote_state.common.outputs.app_insights_instrumentation_key
#   log_analytics_workspace_id       = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
#   enable_diagnostics              = true
#   
#   # Key Vault
#   key_vault_uri = data.terraform_remote_state.common.outputs.key_vault_uri
#   
#   # Runtime configuration
#   runtime_stack  = var.runtime_stack
#   dotnet_version = var.dotnet_version
#   
#   # Health check
#   health_check_path = var.health_check_path
#   
#   # CORS configuration (restrictive by default)
#   cors_allowed_origins = var.cors_allowed_origins
#   
#   # Additional app settings
#   additional_app_settings = merge(
#     var.additional_app_settings,
#     {
#       "ApplicationName" = "UnlockBookings"
#     }
#   )
#   
#   tags = local.tags
# }

