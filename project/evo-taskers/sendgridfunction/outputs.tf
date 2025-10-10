# Outputs for AutomatedDataFeed (all environments)

output "environment" {
  description = "Current environment (workspace name)"
  value       = local.environment
}


output "function_app_name" {
  description = "Name of the Function App"
  value       = module.windows_function_app.function_app_name
}



