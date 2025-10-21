# Outputs for UnlockBookings (all environments)

output "environment" {
  description = "Current environment (workspace name)"
  value       = local.environment
}

# ==============================================================================
# FUNCTION APP OUTPUTS
# ==============================================================================

output "function_app_id" {
  description = "The ID of the UnlockBookings Function App"
  value       = module.function_app.id
}

output "function_app_name" {
  description = "The name of the UnlockBookings Function App"
  value       = module.function_app.name
}

output "function_app_default_hostname" {
  description = "The default hostname of the UnlockBookings Function App"
  value       = module.function_app.default_hostname
}

output "function_app_url" {
  description = "The HTTPS URL of the UnlockBookings Function App"
  value       = "https://${module.function_app.default_hostname}"
}

output "function_app_identity_principal_id" {
  description = "The principal ID of the UnlockBookings Function App managed identity"
  value       = module.function_app.identity_principal_id
}

# ==============================================================================
# LOGIC APP OUTPUTS
# ==============================================================================

output "logic_app_id" {
  description = "The ID of the UnlockBookings Logic App"
  value       = module.logic_app_standard.id
}

output "logic_app_name" {
  description = "The name of the UnlockBookings Logic App"
  value       = module.logic_app_standard.name
}

output "logic_app_default_hostname" {
  description = "The default hostname of the UnlockBookings Logic App"
  value       = module.logic_app_standard.default_hostname
}

output "logic_app_url" {
  description = "The HTTPS URL of the UnlockBookings Logic App"
  value       = "https://${module.logic_app_standard.default_hostname}"
}

output "logic_app_identity_principal_id" {
  description = "The principal ID of the UnlockBookings Logic App managed identity"
  value       = module.logic_app_standard.identity_principal_id
}

# ==============================================================================
# SHARED INFRASTRUCTURE REFERENCES
# ==============================================================================

output "shared_windows_function_plan_id" {
  description = "The ID of the shared Windows Function App Service Plan (from shared state)"
  value       = data.terraform_remote_state.shared.outputs.windows_function_plan_id
}

output "shared_logic_app_plan_id" {
  description = "The ID of the shared Logic App Service Plan (from shared state)"
  value       = data.terraform_remote_state.shared.outputs.logic_app_plan_id
}

