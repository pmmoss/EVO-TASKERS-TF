# Function App Module

This module provisions an Azure Function App with managed identity, Application Insights, and optional VNet integration.

## Usage
```hcl
module "function_app" {
  source                = "./modules/function_app"
  resource_group_name   = var.resource_group_name
  location              = var.location
  storage_account_name  = var.storage_account_name
  app_insights_key      = var.app_insights_key
  enable_vnet_integration = true
  subnet_id             = var.subnet_id
  tags                  = var.tags
}
```

## Inputs
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `storage_account_name`: Storage account for the function app
- `app_insights_key`: App Insights instrumentation key
- `enable_vnet_integration`: (bool) Enable VNet integration
- `subnet_id`: Subnet for VNet integration
- `tags`: Map of tags

## Outputs
- `function_app_id`, `function_app_default_hostname`, `function_app_identity`
