# Naming Module

This module standardizes resource naming according to Microsoft best practices and abbreviations, with support for Azure-specific naming constraints.

## Usage

### Basic Usage
```hcl
module "naming" {
  source = "./modules/naming"
  resource_type = "rg"
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}
```

### For Storage Accounts
```hcl
module "naming_storage" {
  source = "./modules/naming"
  resource_type = "st"
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

resource "azurerm_storage_account" "this" {
  name = module.naming_storage.storage_name
  # ... other configuration
}
```

### For Key Vaults
```hcl
module "naming_kv" {
  source = "./modules/naming"
  resource_type = "kv"
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

resource "azurerm_key_vault" "this" {
  name = module.naming_kv.keyvault_name
  # ... other configuration
}
```

## Inputs
- `resource_type`: Abbreviation (e.g., `rg`, `vnet`, `kv`, `st`)
- `project`: Project short name
- `environment`: Environment short name (dev, test, prod)
- `location`: Azure region full name (e.g., `West US 2`)
- `location_short`: Azure region short name (e.g., `wus2`)

## Outputs
- `name`: Standardized resource name with hyphens (for most resources)
- `storage_name`: Azure Storage Account name (no hyphens, lowercase, 3-24 chars)
- `keyvault_name`: Azure Key Vault name (no hyphens, 3-24 chars, alphanumeric only)
- `azure_name`: Generic Azure resource name (no hyphens for most Azure resources)

## Naming Patterns

### Standard Pattern (with hyphens)
- Format: `<type>-<project>-<env>-<location>`
- Example: `rg-evo-taskers-dev-wus2`

### Azure Storage Account Pattern
- Format: `<type><project><env><location>` (no hyphens)
- Example: `stevotaskersdevwus2`
- Constraints: 3-24 characters, lowercase, alphanumeric only

### Azure Key Vault Pattern
- Format: `<type><project><env><location>` (no hyphens)
- Example: `kvevotaskersdevwus2`
- Constraints: 3-24 characters, alphanumeric only

## Reference
- [Microsoft Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [Azure Storage Account Naming Rules](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name)
- [Azure Key Vault Naming Rules](https://docs.microsoft.com/en-us/azure/key-vault/general/about-keys-secrets-certificates#vault-name-and-object-name)
