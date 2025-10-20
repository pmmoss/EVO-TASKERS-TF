output "id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}

output "name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.this.name
}

output "os_type" {
  description = "The OS type of the App Service Plan"
  value       = azurerm_service_plan.this.os_type
}

output "sku_name" {
  description = "The SKU name of the App Service Plan"
  value       = azurerm_service_plan.this.sku_name
}

output "location" {
  description = "The Azure region where the App Service Plan is located"
  value       = azurerm_service_plan.this.location
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_service_plan.this.resource_group_name
}

output "zone_balancing_enabled" {
  description = "Whether zone balancing is enabled"
  value       = azurerm_service_plan.this.zone_balancing_enabled
}

output "worker_count" {
  description = "The number of workers"
  value       = azurerm_service_plan.this.worker_count
}

output "maximum_elastic_worker_count" {
  description = "The maximum elastic worker count"
  value       = azurerm_service_plan.this.maximum_elastic_worker_count
}

output "per_site_scaling_enabled" {
  description = "Whether per-site scaling is enabled"
  value       = azurerm_service_plan.this.per_site_scaling_enabled
}

