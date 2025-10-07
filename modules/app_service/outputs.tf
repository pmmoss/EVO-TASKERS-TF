output "app_service_id" {
  value       = azurerm_linux_web_app.this.id
  description = "The ID of the App Service"
}

output "app_service_name" {
  value       = azurerm_linux_web_app.this.name
  description = "The name of the App Service"
}

output "app_service_default_hostname" {
  value       = azurerm_linux_web_app.this.default_hostname
  description = "The default hostname of the App Service"
}

output "app_service_identity_principal_id" {
  value       = azurerm_linux_web_app.this.identity[0].principal_id
  description = "The principal ID of the App Service's managed identity"
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
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.app_service[0].id : null
  description = "The ID of the private endpoint (if enabled)"
}

output "private_endpoint_private_ip" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.app_service[0].private_service_connection[0].private_ip_address : null
  description = "The private IP address of the private endpoint (if enabled)"
}

