# Resource Group
output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "resource_group_id" {
  value = azurerm_resource_group.this.id
}

# Network
output "vnet_id" {
  value = module.network.vnet_id
}
  environment   = var.environment
output "vnet_name" {
  value = module.network.vnet_name
}

output "app_integration_subnet_id" {
  value = module.network.app_integration_subnet_id
}

output "private_endpoints_subnet_id" {
  value = module.network.private_endpoints_subnet_id
}

output "gateway_subnet_id" {
  value = module.network.gateway_subnet_id
}

# Log Analytics
output "log_analytics_workspace_id" {
  value = module.log_analytics.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  value = module.log_analytics.log_analytics_workspace_name
}

# Key Vault
output "key_vault_id" {
  value = module.key_vault.key_vault_id
}

output "key_vault_uri" {
  value = module.key_vault.key_vault_uri
}

# Storage Account
output "storage_account_id" {
  value = module.storage.storage_account_id
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_primary_access_key" {
  value     = module.storage.storage_account_primary_access_key
  sensitive = true
  description = "Primary access key for storage account (for Function Apps)"
}

# Application Insights
output "app_insights_id" {
  value = module.app_insights.app_insights_id
}

output "app_insights_instrumentation_key" {
  value = module.app_insights.app_insights_instrumentation_key
  sensitive = true
}

# Bastion
output "bastion_host_id" {
  value = var.enable_bastion ? module.bastion[0].bastion_host_id : null
}

output "bastion_public_ip_address" {
  value = var.enable_bastion ? module.bastion[0].bastion_public_ip_address : null
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
  value = module.app_insights.app_insights_connection_string
  sensitive = true
  description = "Application Insights connection string"
}
