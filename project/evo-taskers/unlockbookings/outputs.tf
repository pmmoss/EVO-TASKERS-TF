
# Function App Outputs
output "function_app_id" {
  value       = module.function_app.function_app_id
  description = "The ID of the Function App"
}

output "function_app_name" {
  value       = module.function_app.function_app_name
  description = "The name of the Function App"
}

output "function_app_default_hostname" {
  value       = module.function_app.function_app_default_hostname
  description = "The default hostname of the Function App"
}

output "function_app_url" {
  value       = "https://${module.function_app.function_app_default_hostname}"
  description = "The HTTPS URL of the Function App"
}

output "function_app_service_plan_id" {
  value       = module.function_app.service_plan_id
  description = "The ID of the Function App Service Plan"
}

# Logic App Standard Outputs
output "logic_app_id" {
  value       = module.logic_app_standard.logic_app_id
  description = "The ID of the Logic App"
}

output "logic_app_name" {
  value       = module.logic_app_standard.logic_app_name
  description = "The name of the Logic App"
}

output "logic_app_default_hostname" {
  value       = module.logic_app_standard.logic_app_default_hostname
  description = "The default hostname of the Logic App"
}

output "logic_app_url" {
  value       = "https://${module.logic_app_standard.logic_app_default_hostname}"
  description = "The HTTPS URL of the Logic App"
}

output "logic_app_service_plan_id" {
  value       = module.logic_app_standard.service_plan_id
  description = "The ID of the Logic App Service Plan"
}

