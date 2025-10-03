# App Insights Module

This module provisions an Application Insights instance for monitoring.

## Usage
```hcl
module "appinsights" {
  source              = "./modules/appinsights"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
```

## Inputs
- `resource_group_name`: Name of the resource group
- `location`: Azure region
- `tags`: Map of tags

## Outputs
- `app_insights_id`, `app_insights_instrumentation_key`
