# Outputs for SendGridFunction (all environments)

output "environment" {
  description = "Current environment (workspace name)"
  value       = local.environment
}

# ==============================================================================
# FUNCTION APP OUTPUTS
# ==============================================================================

output "function_app_id" {
  description = "The ID of the SendGridFunction Function App"
  value       = module.windows_function_app.id
}

output "function_app_name" {
  description = "The name of the SendGridFunction Function App"
  value       = module.windows_function_app.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the SendGridFunction Function App"
  value       = module.windows_function_app.default_hostname
}

output "function_app_identity_principal_id" {
  description = "The principal ID of the SendGridFunction Function App managed identity"
  value       = module.windows_function_app.identity_principal_id
}

# ==============================================================================
# SHARED INFRASTRUCTURE REFERENCES
# ==============================================================================

output "shared_windows_function_plan_id" {
  description = "The ID of the shared Windows Function App Service Plan (from shared state)"
  value       = data.terraform_remote_state.shared.outputs.windows_function_plan_id
}

