
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

