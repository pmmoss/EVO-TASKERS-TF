# Network Module

This module provisions a Virtual Network, subnets, NSGs, route tables, and private endpoint subnet for secure landing zones. Uses Azure Verified Modules where possible.

## Usage
```hcl
module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_address_space  = ["10.10.0.0/16"]
  subnets             = [
    { name = "app", address_prefix = "10.10.1.0/24" },
    { name = "pe",  address_prefix = "10.10.2.0/24" }
  ]
  tags                = var.tags
}
```

## Inputs
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `vnet_address_space`: List of address spaces
- `subnets`: List of subnet maps (name, address_prefix)
- `tags`: Map of tags

## Outputs
- `vnet_id`, `subnet_ids`, `pe_subnet_id`
