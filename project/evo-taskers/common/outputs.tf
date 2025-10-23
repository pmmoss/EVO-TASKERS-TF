# Resource Group
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

# Network
output "vnet_id" {
  value = module.vnet.id
}

output "vnet_name" {
  value = module.vnet.name
}

output "app_integration_subnet_id" {
  value = module.vnet.subnets["app_service_integration"].id
}

output "private_endpoints_subnet_id" {
  value = module.vnet.subnets["private_endpoints"].id
}

output "gateway_subnet_id" {
  value = module.vnet.subnets["gateway"].id
}

# Log Analytics
output "log_analytics_workspace_id" {
  value = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  value = module.log_analytics.name
}

# Key Vault
output "key_vault_id" {
  value = module.key_vault.id
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

# Storage Account
output "storage_account_id" {
  value = module.storage.id
}

output "storage_account_name" {
  value = module.storage.name
}

output "storage_account_primary_access_key" {
  value     = module.storage.primary_access_key
  sensitive = true
  description = "Primary access key for storage account (for Function Apps)"
}

# Application Insights
output "app_insights_id" {
  value = module.app_insights.id
}

output "app_insights_instrumentation_key" {
  value = module.app_insights.instrumentation_key
  sensitive = true
}

# Bastion
output "bastion_host_id" {
  value = var.enable_bastion ? module.bastion[0].id : null
}

output "bastion_public_ip_address" {
  value = var.enable_bastion ? module.bastion[0].public_ip_address : null
}

# User-Assigned Managed Identity
output "workload_identity_id" {
  value = azurerm_user_assigned_identity.workload.id
  description = "The ID of the user-assigned managed identity for workloads"
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
  description = "The client ID of the user-assigned managed identity for workloads"
}

output "workload_identity_principal_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
  description = "The principal ID of the user-assigned managed identity for workloads"
}

# Common configuration
output "location" {
  value = var.location
}

output "location_short" {
  value = var.location_short
}

output "project" {
  value = var.project
}

output "environment" {
  value = var.environment
}

output "tags" {
  value = local.common_tags
}

output "app_insights_connection_string" {
  value = module.app_insights.connection_string
  sensitive = true
  description = "Application Insights connection string"
}

# Service Plans
output "windows_function_plan_id" {
  value = var.function_app_service_plan_existing_service_plan_id != null ? var.function_app_service_plan_existing_service_plan_id : module.avm-res-web-serverfarm_function_app_service_plan.resource_id
  description = "The ID of the Windows Function App Service Plan"
}

output "windows_function_plan_name" {
  value = var.function_app_service_plan_existing_service_plan_id != null ? "existing-plan" : module.avm-res-web-serverfarm_function_app_service_plan.name
  description = "The name of the Windows Function App Service Plan"
}

output "logic_app_plan_id" {
  value = var.logic_app_service_plan_existing_service_plan_id != null ? var.logic_app_service_plan_existing_service_plan_id : module.avm-res-web-serverfarm_logic_app_service_plan.resource_id
  description = "The ID of the Logic App Service Plan"
}

output "logic_app_plan_name" {
  value = var.logic_app_service_plan_existing_service_plan_id != null ? "existing-plan" : module.avm-res-web-serverfarm_logic_app_service_plan.name
  description = "The name of the Logic App Service Plan"
}

output "linux_web_plan_id" {
  value = var.linux_web_app_service_plan_existing_service_plan_id != null ? var.linux_web_app_service_plan_existing_service_plan_id : module.avm-res-web-serverfarm_linux_web_app_service_plan.resource_id
  description = "The ID of the Linux Web App Service Plan"
}

output "linux_web_plan_name" {
  value = var.linux_web_app_service_plan_existing_service_plan_id != null ? "existing-plan" : module.avm-res-web-serverfarm_linux_web_app_service_plan.name
  description = "The name of the Linux Web App Service Plan"
}
