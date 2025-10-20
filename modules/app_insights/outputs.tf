output "app_insights_id" {
  value = azurerm_application_insights.this.id
}

output "app_insights_name" {
  value = azurerm_application_insights.this.name
}

output "app_insights_instrumentation_key" {
  value = azurerm_application_insights.this.instrumentation_key
  sensitive = true
}

output "app_insights_connection_string" {
  value = azurerm_application_insights.this.connection_string
  sensitive = true
}

# output "private_endpoint_id" {
#   value = var.enable_private_endpoint ? azurerm_private_endpoint.app_insights[0].id : null
# }
