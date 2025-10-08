# UnlockBookings uses Function App only - App Service outputs commented out

# App Service Outputs
# output "app_service_id" {
#   value       = module.app_service.app_service_id
#   description = "The ID of the App Service"
# }

# output "app_service_name" {
#   value       = module.app_service.app_service_name
#   description = "The name of the App Service"
# }

# output "app_service_default_hostname" {
#   value       = module.app_service.app_service_default_hostname
#   description = "The default hostname of the App Service"
# }

# output "app_service_url" {
#   value       = "https://${module.app_service.app_service_default_hostname}"
#   description = "The HTTPS URL of the App Service"
# }

# output "service_plan_id" {
#   value       = module.app_service.service_plan_id
#   description = "The ID of the App Service Plan"
# }

# output "service_plan_name" {
#   value       = module.app_service.service_plan_name
#   description = "The name of the App Service Plan"
# }

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

