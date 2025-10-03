output "name" {
  value       = local.name
  description = "Standardized resource name with hyphens (for most resources)."
}

output "storage_name" {
  value       = local.storage_name
  description = "Azure Storage Account name (no hyphens, lowercase, 3-24 chars)."
}

output "keyvault_name" {
  value       = local.keyvault_name
  description = "Azure Key Vault name (no hyphens, 3-24 chars, alphanumeric only)."
}

output "azure_name" {
  value       = local.azure_name
  description = "Generic Azure resource name (no hyphens for most Azure resources)."
}
