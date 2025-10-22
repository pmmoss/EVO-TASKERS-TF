# ==============================================================================
# LINUX WEB APP OUTPUTS
# ==============================================================================

output "web_app_id" {
  value       = module.linux_web_app.resource_id
  description = "The ID of the Linux Web App"
}

output "web_app_name" {
  value       = module.linux_web_app.name
  description = "The name of the Linux Web App"
}

output "web_app_default_hostname" {
  value       = module.linux_web_app.resource_uri
  description = "The default hostname of the Linux Web App"
}

output "web_app_identity_principal_id" {
  value       = module.linux_web_app.identity_principal_id
  description = "The principal ID of the managed identity"
}

output "web_app_resource" {
  value       = module.linux_web_app.resource
  description = "The full Web App resource output"
  sensitive   = true
}


# ==============================================================================
# DEPLOYMENT INFORMATION
# ==============================================================================

output "deployment_info" {
  value = {
    app_name            = var.app_name
    environment         = local.environment
    workspace           = terraform.workspace
    url                 = module.linux_web_app.resource_uri
    runtime_stack       = var.runtime_stack
    sku                 = var.app_service_sku
    private_endpoint    = var.enable_private_endpoint
  }
  description = "Deployment information summary"
}

