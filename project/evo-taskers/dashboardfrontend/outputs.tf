# ==============================================================================
# LINUX WEB APP OUTPUTS
# ==============================================================================

output "web_app_id" {
  value       = module.linux_web_app.app_service_id
  description = "The ID of the Linux Web App"
}

output "web_app_name" {
  value       = module.linux_web_app.app_service_name
  description = "The name of the Linux Web App"
}

output "web_app_default_hostname" {
  value       = module.linux_web_app.app_service_default_hostname
  description = "The default hostname of the Linux Web App"
}

output "web_app_url" {
  value       = module.linux_web_app.app_service_default_site_hostname
  description = "The full URL of the Linux Web App (with HTTPS)"
}

output "web_app_outbound_ip_addresses" {
  value       = module.linux_web_app.app_service_outbound_ip_addresses
  description = "Comma-separated list of outbound IP addresses"
}

output "web_app_identity_principal_id" {
  value       = module.linux_web_app.app_service_identity_principal_id
  description = "The principal ID of the managed identity"
}

output "web_app_identity_tenant_id" {
  value       = module.linux_web_app.app_service_identity_tenant_id
  description = "The tenant ID of the managed identity"
}

# ==============================================================================
# SERVICE PLAN OUTPUTS
# ==============================================================================

output "service_plan_id" {
  value       = module.linux_web_app.service_plan_id
  description = "The ID of the App Service Plan"
}

output "service_plan_name" {
  value       = module.linux_web_app.service_plan_name
  description = "The name of the App Service Plan"
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "private_endpoint_id" {
  value       = module.linux_web_app.private_endpoint_id
  description = "The ID of the private endpoint (if enabled)"
}

output "private_endpoint_private_ip" {
  value       = module.linux_web_app.private_endpoint_private_ip
  description = "The private IP address of the private endpoint (if enabled)"
}

output "vnet_integration_subnet_id" {
  value       = module.linux_web_app.vnet_integration_subnet_id
  description = "The subnet ID used for VNet integration"
}

# ==============================================================================
# DEPLOYMENT SLOT OUTPUTS
# ==============================================================================

output "staging_slot_id" {
  value       = module.linux_web_app.staging_slot_id
  description = "The ID of the staging slot (if enabled)"
}

output "staging_slot_name" {
  value       = module.linux_web_app.staging_slot_name
  description = "The name of the staging slot (if enabled)"
}

output "staging_slot_default_hostname" {
  value       = module.linux_web_app.staging_slot_default_hostname
  description = "The default hostname of the staging slot (if enabled)"
}

# ==============================================================================
# MONITORING OUTPUTS
# ==============================================================================

output "diagnostic_setting_id" {
  value       = module.linux_web_app.diagnostic_setting_id
  description = "The ID of the diagnostic setting (if enabled)"
}

output "autoscale_setting_id" {
  value       = module.linux_web_app.autoscale_setting_id
  description = "The ID of the autoscale setting (if enabled)"
}

# ==============================================================================
# COMPREHENSIVE OUTPUT
# ==============================================================================

output "web_app_details" {
  value       = module.linux_web_app.app_service_details
  description = "Comprehensive details about the Linux Web App"
}

# ==============================================================================
# DEPLOYMENT INFORMATION
# ==============================================================================

output "deployment_info" {
  value = {
    app_name            = var.app_name
    environment         = local.environment
    workspace           = terraform.workspace
    url                 = module.linux_web_app.app_service_default_site_hostname
    runtime_stack       = var.runtime_stack
    sku                 = var.app_service_sku
    private_endpoint    = var.enable_private_endpoint
    staging_slot        = var.create_staging_slot
    autoscaling_enabled = var.enable_autoscale
  }
  description = "Deployment information summary"
}

