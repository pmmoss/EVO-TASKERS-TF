# Outputs for AutomatedDataFeed (all environments)

output "environment" {
  description = "Current environment (workspace name)"
  value       = local.environment
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = module.app_service.app_service_name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = module.app_service.default_hostname
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = module.windows_function_app.function_app_name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = module.windows_function_app.default_hostname
}

