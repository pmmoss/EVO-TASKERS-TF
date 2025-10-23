
# Outputs
output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  value = [
    azurerm_subnet.app_integration.id,
    azurerm_subnet.private_endpoints.id,
    azurerm_subnet.gateway.id,
    azurerm_subnet.bastion.id
  ]
}

output "subnet_names" {
  value = [
    azurerm_subnet.app_integration.name,
    azurerm_subnet.private_endpoints.name,
    azurerm_subnet.gateway.name,
    azurerm_subnet.bastion.name
  ]
}

output "app_integration_subnet_id" {
  value = azurerm_subnet.app_integration.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}
