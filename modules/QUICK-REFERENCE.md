# Quick Reference: Shared App Service Plans

## Before vs After

### ❌ Before: Each App Creates Its Own Plan

```hcl
# dashboard/main.tf
module "dashboard_function" {
  source = "../../modules/windows_function_app"
  
  app_name = "dashboard"
  sku_name = "EP1"  # Creates dedicated EP1 plan
  # ... config
}

# sendgrid/main.tf  
module "sendgrid_function" {
  source = "../../modules/windows_function_app"
  
  app_name = "sendgrid"
  sku_name = "EP1"  # Creates another EP1 plan
  # ... config
}

# Result: 2 plans × $150/month = $300/month
```

### ✅ After: Multiple Apps Share One Plan

```hcl
# common/main.tf (or separate shared.tf)
module "shared_function_plan" {
  source = "../../modules/app_service_plan"
  
  plan_name  = "shared-functions"
  os_type    = "Windows"
  sku_name   = "EP1"
  # ... config
}

# dashboard/main.tf
module "dashboard_function" {
  source = "../../modules/windows_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = module.shared_function_plan.id
  
  app_name = "dashboard"
  # ... config (no sku_name needed)
}

# sendgrid/main.tf
module "sendgrid_function" {
  source = "../../modules/windows_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = module.shared_function_plan.id
  
  app_name = "sendgrid"
  # ... config
}

# Result: 1 plan = $150/month (saves $150/month)
```

## Quick Snippets

### Create a Shared Windows Function Plan

```hcl
module "windows_func_plan" {
  source = "../../modules/app_service_plan"
  
  project             = var.project
  plan_name           = "functions-windows"
  environment         = var.environment
  location            = var.location
  location_short      = var.location_short
  resource_group_name = var.resource_group_name
  
  os_type  = "Windows"
  sku_name = "EP1"
  
  tags = var.tags
}

output "windows_function_plan_id" {
  value = module.windows_func_plan.id
}
```

### Create a Shared Linux Function Plan

```hcl
module "linux_func_plan" {
  source = "../../modules/app_service_plan"
  
  project             = var.project
  plan_name           = "functions-linux"
  environment         = var.environment
  location            = var.location
  location_short      = var.location_short
  resource_group_name = var.resource_group_name
  
  os_type  = "Linux"
  sku_name = "EP1"
  
  tags = var.tags
}
```

### Create a Shared Logic App Plan

```hcl
module "logic_app_plan" {
  source = "../../modules/app_service_plan"
  
  project             = var.project
  plan_name           = "logicapps"
  environment         = var.environment
  location            = var.location
  location_short      = var.location_short
  resource_group_name = var.resource_group_name
  
  os_type  = "Windows"
  sku_name = "WS1"  # Workflow Standard
  
  tags = var.tags
}
```

### Use Existing Plan in Windows Function App

```hcl
module "my_function" {
  source = "../../modules/windows_function_app"
  
  # Point to shared plan
  create_service_plan      = false
  existing_service_plan_id = var.shared_plan_id  # or module.plan.id
  
  # Regular config (no sku_name)
  project             = var.project
  app_name            = "myfunction"
  environment         = var.environment
  # ... rest of config
}
```

### Use Existing Plan in Linux Function App

```hcl
module "my_function" {
  source = "../../modules/linux_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = var.shared_plan_id
  
  project             = var.project
  app_name            = "myfunction"
  environment         = var.environment
  functions_worker_runtime = "node"
  # ... rest of config
}
```

### Use Existing Plan in Logic App

```hcl
module "my_logic_app" {
  source = "../../modules/logic_app_standard"
  
  create_service_plan      = false
  existing_service_plan_id = var.shared_plan_id
  
  project    = var.project
  app_name   = "mylogicapp"
  environment = var.environment
  # ... rest of config
}
```

### Keep Existing Behavior (Each App Has Own Plan)

```hcl
module "my_function" {
  source = "../../modules/windows_function_app"
  
  # No changes needed! Just omit the new variables
  # create_service_plan defaults to true
  
  project     = var.project
  app_name    = "myfunction"
  environment = var.environment
  sku_name    = "EP1"  # Creates its own EP1 plan
  # ... rest of config
}
```

## Common Scenarios

### Scenario 1: All EVO-TASKERS Functions Share One Plan

```hcl
# project/evo-taskers/common/main.tf

# Add this to common module
module "shared_function_plan" {
  source = "../../../modules/app_service_plan"
  
  project             = var.project
  plan_name           = "shared-functions"
  environment         = var.environment
  location            = var.location
  location_short      = var.location_short
  resource_group_name = azurerm_resource_group.this.name
  
  os_type  = "Windows"
  sku_name = "EP1"
  
  enable_autoscale       = true
  autoscale_min_capacity = 1
  autoscale_max_capacity = 5
  
  tags = local.tags
}

# Output the plan ID for other modules
output "shared_function_plan_id" {
  value       = module.shared_function_plan.id
  description = "Shared function app service plan ID"
}
```

Then in each function app:

```hcl
# project/evo-taskers/dashboard/main.tf
data "terraform_remote_state" "common" {
  backend = "azurerm"
  config = {
    # ... your backend config
  }
}

module "dashboard_function" {
  source = "../../../modules/windows_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.common.outputs.shared_function_plan_id
  
  # Rest of config
  app_name = "dashboard"
  # ...
}
```

### Scenario 2: Per-Environment Strategy

```hcl
# Dev: Each app has consumption plan (cheapest)
module "dev_function" {
  source = "../../modules/windows_function_app"
  
  count = var.environment == "dev" ? 1 : 0
  
  create_service_plan = true
  sku_name           = "Y1"  # Consumption
  # ...
}

# Prod: Shared premium plan (best performance)
module "prod_function" {
  source = "../../modules/windows_function_app"
  
  count = var.environment == "prod" ? 1 : 0
  
  create_service_plan      = false
  existing_service_plan_id = var.shared_premium_plan_id
  # ...
}
```

### Scenario 3: Mixed SKUs for Different Workloads

```hcl
# Critical functions: High-tier shared plan
module "critical_plan" {
  source = "../../modules/app_service_plan"
  sku_name = "EP3"
  zone_redundant = true
  # ...
}

module "critical_function_1" {
  source = "../../modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.critical_plan.id
  # ...
}

# Background jobs: Lower-tier shared plan  
module "background_plan" {
  source = "../../modules/app_service_plan"
  sku_name = "EP1"
  # ...
}

module "background_job_1" {
  source = "../../modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.background_plan.id
  # ...
}
```

## Variable Cheat Sheet

### When `create_service_plan = true` (default)

```hcl
module "app" {
  source = "../../modules/windows_function_app"
  
  # Required
  sku_name = "EP1"  # ← Must provide SKU
  
  # These create a new plan
  project
  app_name
  environment
  location
  location_short
  resource_group_name
}
```

### When `create_service_plan = false`

```hcl
module "app" {
  source = "../../modules/windows_function_app"
  
  # Required
  create_service_plan      = false
  existing_service_plan_id = module.plan.id  # ← Must provide plan ID
  
  # NOT needed: sku_name (ignored)
  
  # Still required
  project
  app_name
  environment
  location
  location_short
  resource_group_name
}
```

## SKU Quick Reference

| SKU | Type | OS | Use Case | Cost (approx) |
|-----|------|----|-----------| --------------|
| Y1 | Consumption | Win/Lin | Dev/test, sporadic | Pay per execution |
| EP1 | Elastic Premium | Win/Lin | Production, small | ~$150/mo |
| EP2 | Elastic Premium | Win/Lin | Production, medium | ~$300/mo |
| EP3 | Elastic Premium | Win/Lin | Production, large | ~$600/mo |
| B1 | Basic | Win/Lin | Dev web apps | ~$13/mo |
| S1 | Standard | Win/Lin | Prod web apps | ~$70/mo |
| P1V3 | Premium V3 | Win/Lin | High-perf web | ~$150/mo |
| WS1 | Workflow Std | Windows | Logic Apps | ~$225/mo |

## Outputs Reference

### app_service_plan module outputs

```hcl
module.plan.id                   # The plan ID (use for existing_service_plan_id)
module.plan.name                 # The plan name
module.plan.os_type              # "Windows" or "Linux"
module.plan.sku_name             # The SKU
module.plan.location             # Azure region
```

### Function app module outputs

```hcl
module.function.service_plan_id         # Plan ID (created or provided)
module.function.service_plan_name       # Plan name (null if using existing)
module.function.function_app_id         # Function app resource ID
module.function.function_app_name       # Function app name
module.function.function_app_default_hostname  # FQDN
```

## Remote State Example

If your app service plan is in a different Terraform state (e.g., in `common` module):

```hcl
# dashboard/main.tf

# Reference the common state
data "terraform_remote_state" "common" {
  backend = "azurerm"
  
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "evo-taskers/common/terraform.tfstate"
  }
}

module "dashboard_function" {
  source = "../../../modules/windows_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.common.outputs.shared_function_plan_id
  
  # ... rest of config
}
```

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "service_plan_id is empty" | Forgot to set `existing_service_plan_id` | Add: `existing_service_plan_id = module.plan.id` |
| "OS type mismatch" | Wrong OS for plan | Windows app needs Windows plan, Linux app needs Linux plan |
| "sku_name is required" | `create_service_plan = true` but no SKU | Add: `sku_name = "EP1"` |
| "Plan not found" | Plan doesn't exist yet | Ensure plan module runs before app module |
| Apps not working | Too many apps on plan | Upgrade SKU or enable autoscaling |

## Resource Naming

Modules follow this naming convention:

```
App Service Plan: asp-{project}-{environment}-{location_short}-{plan_name}
Example: asp-evotaskers-prod-eus-shared-functions

Function App: fa-{project}-{environment}-{location_short}-{app_name}
Example: fa-evotaskers-prod-eus-dashboard

Logic App: la-{project}-{environment}-{location_short}-{app_name}
Example: la-evotaskers-prod-eus-unlockbookings
```

## Need More Help?

- See [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) for detailed scenarios
- See [app_service_plan/README.md](./app_service_plan/README.md) for full module docs
- Check existing module READMEs for specific app types

