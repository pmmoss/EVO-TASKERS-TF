output "function_app_id" {
  value       = azurerm_linux_function_app.this.id
  description = "The ID of the Function App"
}

output "function_app_name" {
  value       = azurerm_linux_function_app.this.name
  description = "The name of the Function App"
}

output "function_app_default_hostname" {
  value       = azurerm_linux_function_app.this.default_hostname
  description = "The default hostname of the Function App"
}

output "function_app_identity_principal_id" {
  value       = azurerm_linux_function_app.this.identity[0].principal_id
  description = "The principal ID of the Function App's managed identity"
}

output "service_plan_id" {
  value       = azurerm_service_plan.this.id
  description = "The ID of the App Service Plan"
}

output "service_plan_name" {
  value       = azurerm_service_plan.this.name
  description = "The name of the App Service Plan"
}

output "private_endpoint_id" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.function_app[0].id : null
  description = "The ID of the private endpoint (if enabled)"
}

output "private_endpoint_private_ip" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.function_app[0].private_service_connection[0].private_ip_address : null
  description = "The private IP address of the private endpoint (if enabled)"
}

