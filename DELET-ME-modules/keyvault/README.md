# Key Vault Module

This module provisions an Azure Key Vault with private endpoint, RBAC, and diagnostic settings.

## Usage
```hcl
module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_id             = var.vnet_id
  subnet_id           = var.pe_subnet_id
  tags                = var.tags
}
```

## Inputs
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `vnet_id`: Virtual Network ID
- `subnet_id`: Private endpoint subnet ID
- `tags`: Map of tags

## Outputs
- `key_vault_id`, `key_vault_uri`
