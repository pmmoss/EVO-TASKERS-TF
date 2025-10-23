# Log Analytics Workspace Module

This module provisions a Log Analytics workspace for diagnostics and monitoring.

## Usage
```hcl
module "log_analytics" {
  source              = "./modules/log_analytics"
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
- `log_analytics_workspace_id`, `log_analytics_workspace_name`
