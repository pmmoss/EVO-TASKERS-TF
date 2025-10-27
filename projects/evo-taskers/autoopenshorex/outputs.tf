# Outputs for AutoOpenShoreX (all environments)

output "environment" {
  description = "Current environment (workspace name)"
  value       = local.environment
}

# ==============================================================================
# FUNCTION APP OUTPUTS (AVM Module)
# ==============================================================================

output "function_app_id" {
  description = "The ID of the AutoOpenShoreX Function App"
  value       = module.windows_function_app.resource_id
}

output "function_app_name" {
  description = "The name of the AutoOpenShoreX Function App"
  value       = module.windows_function_app.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the AutoOpenShoreX Function App"
  value       = module.windows_function_app.resource_uri
}

output "function_app_identity_principal_id" {
  description = "The principal ID of the AutoOpenShoreX Function App managed identity"
  value       = module.windows_function_app.identity_principal_id
}

output "function_app_resource" {
  description = "The full Function App resource output"
  value       = module.windows_function_app.resource
  sensitive   = true
}

# ==============================================================================
# SHARED INFRASTRUCTURE REFERENCES
# ==============================================================================

output "shared_windows_function_plan_id" {
  description = "The ID of the shared Windows Function App Service Plan (from common state)"
  value       = data.terraform_remote_state.common.outputs.windows_function_plan_id
}

