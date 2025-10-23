# Storage Account Module

This module provisions a secure Azure Storage Account with private endpoint and diagnostic settings.

## Usage
```hcl
module "storage" {
  source              = "./modules/storage"
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
- `storage_account_id`, `primary_connection_string`
