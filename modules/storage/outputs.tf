output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_primary_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "private_endpoint_id" {
  value = azurerm_private_endpoint.storage.id
}
output "primary_connection_string" {
  value = azurerm_storage_account.this.primary_connection_string
}
