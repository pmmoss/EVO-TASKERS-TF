# Linux Web App for Dashboard Frontend

module "linux_web_app" {
  source = "../../../modules/linux_web_app"
  
  # Application identifier
  app_name = var.app_name
  
  # Project configuration from common infrastructure
  # Environment is automatically derived from workspace name
  project        = local.project
  environment    = local.environment
  location       = local.location
  location_short = local.location_short
  
  # Resource group
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  # App Service Plan Configuration
  sku_name   = var.app_service_sku
  always_on  = var.app_service_always_on
  
  # Runtime Configuration
  runtime_stack  = var.runtime_stack
  dotnet_version = var.runtime_stack == "dotnet" ? var.dotnet_version : null
  node_version   = var.runtime_stack == "node" ? var.node_version : null
  python_version = var.runtime_stack == "python" ? var.python_version : null
  
  # Identity - User-assigned identity from common infrastructure
  identity_type                    = "UserAssigned"
  user_assigned_identity_ids       = [data.terraform_remote_state.common.outputs.workload_identity_id]
  user_assigned_identity_client_id = data.terraform_remote_state.common.outputs.workload_identity_client_id
  key_vault_reference_identity_id  = data.terraform_remote_state.common.outputs.workload_identity_id
  
  # Networking - VNet integration for outbound traffic
  enable_vnet_integration = true
  subnet_id              = data.terraform_remote_state.common.outputs.app_integration_subnet_id
  
  # Private endpoint for inbound traffic (optional, recommended for production)
  enable_private_endpoint    = var.enable_private_endpoint
  private_endpoint_subnet_id = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
  
  # Public network access (disabled if private endpoint is enabled)
  public_network_access_enabled = !var.enable_private_endpoint
  
  # Security Settings
  https_only          = var.https_only
  minimum_tls_version = var.minimum_tls_version
  ftps_state          = var.ftps_state
  
  # Performance Settings
  http2_enabled     = var.http2_enabled
  websockets_enabled = var.websockets_enabled
  use_32_bit_worker = false  # Always use 64-bit for better performance
  
  # CORS Configuration
  cors_allowed_origins     = var.cors_allowed_origins
  cors_support_credentials = var.cors_support_credentials
  
  # Health Check
  health_check_path          = var.health_check_path
  health_check_eviction_time = var.health_check_eviction_time
  
  # Auto-Heal Configuration
  enable_auto_heal                         = var.enable_auto_heal
  auto_heal_action_type                    = var.auto_heal_action_type
  auto_heal_trigger_requests_count         = var.auto_heal_trigger_requests_count
  auto_heal_trigger_requests_interval      = var.auto_heal_trigger_requests_interval
  auto_heal_minimum_process_execution_time = var.auto_heal_minimum_process_execution_time
  
  # Monitoring
  app_insights_connection_string = data.terraform_remote_state.common.outputs.app_insights_connection_string
  log_analytics_workspace_id     = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
  enable_diagnostics             = var.enable_diagnostics
  diagnostic_log_categories      = var.diagnostic_log_categories
  
  # Key Vault Integration
  key_vault_uri = data.terraform_remote_state.common.outputs.key_vault_uri
  
  # Deployment Slot (for staging/blue-green deployments)
  create_staging_slot       = var.create_staging_slot
  staging_slot_name         = var.staging_slot_name
  staging_slot_app_settings = var.staging_slot_app_settings
  
  # Autoscaling Configuration (for production workloads)
  enable_autoscale           = var.enable_autoscale
  autoscale_min_capacity     = var.autoscale_min_capacity
  autoscale_max_capacity     = var.autoscale_max_capacity
  autoscale_default_capacity = var.autoscale_default_capacity
  autoscale_cpu_threshold_up   = var.autoscale_cpu_threshold_up
  autoscale_cpu_threshold_down = var.autoscale_cpu_threshold_down
  
  # Alerting
  # enable_alerts                 = var.enable_alerts
  # alert_action_group_id         = var.alert_action_group_id
  # alert_cpu_threshold           = var.alert_cpu_threshold
  # alert_memory_threshold        = var.alert_memory_threshold
  # alert_response_time_threshold = var.alert_response_time_threshold
  # alert_http_errors_threshold   = var.alert_http_errors_threshold
  
  # IP Restrictions (if needed)
  ip_restrictions     = var.ip_restrictions
  scm_ip_restrictions = var.scm_ip_restrictions
  
  # Application Settings
  additional_app_settings = merge(
    var.additional_app_settings,
    {
      "ApplicationName" = "DashboardFrontend"
      "Workspace"       = terraform.workspace
      "Environment"     = local.environment
    }
  )
  
  # Connection Strings (if needed)
  connection_strings = var.connection_strings
  
  # Sticky Settings (for deployment slots)
  # sticky_app_setting_names       = var.sticky_app_setting_names
  # sticky_connection_string_names = var.sticky_connection_string_names
  
  tags = local.tags
}
