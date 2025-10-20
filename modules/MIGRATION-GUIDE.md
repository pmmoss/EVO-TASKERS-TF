# App Service Plan Separation - Migration Guide

## Overview

The modules have been refactored to separate App Service Plans from app resources (Function Apps, Logic Apps, Web Apps). This allows you to:

1. **Share App Service Plans** across multiple apps to optimize costs
2. **Choose which plan** each app should use
3. **Maintain backward compatibility** with existing configurations

## What Changed

### New Module: `app_service_plan`

A dedicated module for creating App Service Plans that can be shared across multiple apps.

### Updated Modules

All app modules now support two modes:

1. **Create Mode** (default): Creates its own App Service Plan (backward compatible)
2. **Use Existing Mode**: Uses an existing App Service Plan

Updated modules:
- `linux_function_app`
- `windows_function_app`
- `logic_app_standard`
- `linux_web_app` (already had this pattern)

## Migration Options

### Option 1: No Changes Required (Backward Compatible)

Your existing configurations will continue to work without any changes. Each app will create its own App Service Plan.

```hcl
module "my_function" {
  source = "./modules/windows_function_app"
  
  # All existing variables work as before
  project    = "evotaskers"
  app_name   = "dashboard"
  environment = "dev"
  # ... other variables
}
```

### Option 2: Migrate to Shared Plans

#### Step 1: Create a Shared App Service Plan

```hcl
# Create a shared plan for all Windows function apps
module "shared_windows_function_plan" {
  source = "./modules/app_service_plan"
  
  project            = "evotaskers"
  plan_name          = "functions-windows"
  environment        = "dev"
  location           = "East US"
  location_short     = "eus"
  resource_group_name = module.common.resource_group_name
  
  os_type  = "Windows"
  sku_name = "EP1"  # Elastic Premium
  
  plan_purpose = "Shared Windows Function Apps"
  
  tags = local.tags
}
```

#### Step 2: Update Function Apps to Use Shared Plan

```hcl
module "dashboard_function" {
  source = "./modules/windows_function_app"
  
  # Disable service plan creation
  create_service_plan      = false
  existing_service_plan_id = module.shared_windows_function_plan.id
  
  # Regular app configuration
  project    = "evotaskers"
  app_name   = "dashboard"
  environment = "dev"
  # ... other variables
}

module "sendgrid_function" {
  source = "./modules/windows_function_app"
  
  # Use the same shared plan
  create_service_plan      = false
  existing_service_plan_id = module.shared_windows_function_plan.id
  
  project    = "evotaskers"
  app_name   = "sendgrid"
  environment = "dev"
  # ... other variables
}
```

## Common Patterns

### Pattern 1: Shared Plan for Multiple Function Apps

Best for: Cost optimization, consistent scaling

```hcl
# One plan for all production Windows functions
module "prod_function_plan" {
  source = "./modules/app_service_plan"
  
  project    = "evotaskers"
  plan_name  = "prod-functions"
  environment = "prod"
  # ... config
  
  os_type  = "Windows"
  sku_name = "EP2"
  
  # Enable autoscaling for production
  enable_autoscale           = true
  autoscale_min_capacity     = 2
  autoscale_max_capacity     = 10
  autoscale_cpu_threshold_up = 70
}

# Multiple functions use this plan
module "function_1" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.prod_function_plan.id
  # ... config
}

module "function_2" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.prod_function_plan.id
  # ... config
}
```

### Pattern 2: Separate Plans by Workload Type

Best for: Isolation, different scaling requirements

```hcl
# Plan for critical, always-on functions
module "critical_function_plan" {
  source = "./modules/app_service_plan"
  
  plan_name  = "critical-functions"
  sku_name   = "EP3"
  worker_count = 3
  zone_redundant = true
  # ... config
}

# Plan for batch/scheduled functions
module "batch_function_plan" {
  source = "./modules/app_service_plan"
  
  plan_name  = "batch-functions"
  sku_name   = "EP1"
  # ... config
}

# Critical function uses high-tier plan
module "critical_function" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.critical_function_plan.id
  # ... config
}

# Batch function uses lower-tier plan
module "batch_function" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.batch_function_plan.id
  # ... config
}
```

### Pattern 3: Environment-Based Strategy

Best for: Different cost/performance balance per environment

```hcl
# Dev: Individual consumption plans (cheapest)
module "dev_dashboard" {
  source = "./modules/windows_function_app"
  
  create_service_plan = true  # Each creates its own
  sku_name           = "Y1"   # Consumption
  environment        = "dev"
  # ... config
}

# Prod: Shared premium plan (best performance)
module "prod_shared_plan" {
  source = "./modules/app_service_plan"
  
  sku_name = "EP2"
  enable_autoscale = true
  # ... config
}

module "prod_dashboard" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.prod_shared_plan.id
  # ... config
}
```

### Pattern 4: Mixed OS Types

```hcl
# Windows plan for .NET functions
module "windows_function_plan" {
  source = "./modules/app_service_plan"
  
  os_type  = "Windows"
  sku_name = "EP1"
  # ... config
}

# Linux plan for Node/Python functions
module "linux_function_plan" {
  source = "./modules/app_service_plan"
  
  os_type  = "Linux"
  sku_name = "EP1"
  # ... config
}

module "dotnet_function" {
  source                   = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.windows_function_plan.id
  # ... config
}

module "node_function" {
  source                   = "./modules/linux_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.linux_function_plan.id
  # ... config
}
```

## New Variables Reference

### All App Modules

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_service_plan` | `bool` | `true` | Create a new plan or use existing |
| `existing_service_plan_id` | `string` | `null` | ID of existing plan (required if `create_service_plan = false`) |
| `sku_name` | `string` | varies | SKU for the plan (only used if `create_service_plan = true`) |

### App Service Plan Module

See [modules/app_service_plan/README.md](./app_service_plan/README.md) for full documentation.

Key variables:
- `plan_name`: Suffix for the plan name
- `os_type`: "Linux" or "Windows"
- `sku_name`: Plan SKU (Y1, EP1, P1V3, WS1, etc.)
- `enable_autoscale`: Enable autoscaling
- `zone_redundant`: Enable zone redundancy
- `per_site_scaling_enabled`: Allow apps to scale independently

## Cost Optimization Tips

### Scenario 1: Multiple Small Functions

**Before**: Each function has its own EP1 plan = 3 × $150/month = $450/month

```hcl
module "func1" {
  source = "./modules/windows_function_app"
  sku_name = "EP1"
  # ... each creates own plan
}
module "func2" { ... }
module "func3" { ... }
```

**After**: One shared EP1 plan = $150/month (saves $300/month)

```hcl
module "shared_plan" {
  source = "./modules/app_service_plan"
  sku_name = "EP1"
}
module "func1" {
  source = "./modules/windows_function_app"
  create_service_plan = false
  existing_service_plan_id = module.shared_plan.id
}
# func2, func3 use same plan
```

### Scenario 2: Dev/Test Workloads

Use Consumption plans (Y1) for dev/test - only pay when executing:

```hcl
module "dev_function" {
  source = "./modules/windows_function_app"
  
  create_service_plan = true
  sku_name           = "Y1"  # Consumption - pay per execution
  always_on          = false # Not available on Y1
}
```

### Scenario 3: Traffic-Based Scaling

Share a plan with autoscaling across similar workloads:

```hcl
module "api_plan" {
  source = "./modules/app_service_plan"
  
  sku_name = "EP1"
  
  enable_autoscale           = true
  autoscale_min_capacity     = 1
  autoscale_max_capacity     = 5
  autoscale_cpu_threshold_up = 70
}
```

## SKU Recommendations

### Function Apps

| Scenario | SKU | Reason |
|----------|-----|--------|
| Dev/Test | Y1 | Pay per execution, no baseline cost |
| Low traffic production | EP1 | Pre-warmed, VNet support, always on |
| Medium traffic | EP2 | More compute power |
| High traffic / critical | EP3 or P3V3 | Maximum performance |
| Sporadic workload | Y1 or EP1 with autoscale | Scale to zero or near-zero |

### Logic Apps

| Scenario | SKU | Reason |
|----------|-----|--------|
| Standard workflows | WS1 | Entry tier for Logic Apps Standard |
| High throughput | WS2, WS3 | More compute and memory |

### Web Apps

| Scenario | SKU | Reason |
|----------|-----|--------|
| Dev/Test | B1, B2, B3 | Basic tier, low cost |
| Production | S1, S2, S3 | Standard tier, autoscale |
| High performance | P1V3, P2V3, P3V3 | Premium v3, best performance |

## Rollback Plan

If you need to rollback after migrating to shared plans:

1. **Add back `create_service_plan = true`** to each app module
2. **Remove `existing_service_plan_id`** from each app module
3. **Apply changes** - Terraform will create individual plans
4. **Remove the shared plan module** after all apps are migrated back

Example:
```hcl
module "my_function" {
  source = "./modules/windows_function_app"
  
  # Change these
  create_service_plan      = true   # was: false
  # existing_service_plan_id = ...  # remove this line
  sku_name                 = "EP1"  # specify SKU
  
  # Rest stays the same
  app_name = "myapp"
  # ...
}
```

## Troubleshooting

### Error: "service_plan_id cannot be empty"

**Cause**: `create_service_plan = false` but no `existing_service_plan_id` provided

**Fix**: Provide the plan ID:
```hcl
existing_service_plan_id = module.my_plan.id
```

### Error: "OS type mismatch"

**Cause**: Trying to use a Windows plan for Linux app (or vice versa)

**Fix**: Ensure plan and app OS types match:
- Windows Function App → Windows plan (os_type = "Windows")
- Linux Function App → Linux plan (os_type = "Linux")

### Plan at capacity / performance issues

**Cause**: Too many apps on one plan

**Fix**: Either:
1. Upgrade plan SKU: `sku_name = "EP2"` → `sku_name = "EP3"`
2. Enable autoscaling: `enable_autoscale = true`
3. Split apps across multiple plans

## Best Practices

1. **Group similar workloads** on the same plan (similar scaling patterns)
2. **Use separate plans for production and non-production** environments
3. **Enable autoscaling** for variable workloads on shared plans
4. **Monitor plan metrics** (CPU, memory) to ensure adequate capacity
5. **Use zone redundancy** for production plans (Premium SKUs)
6. **Tag plans** with purpose/workload information for cost tracking
7. **Start with shared plans** in dev/test before production

## Next Steps

1. Review your current app deployments
2. Identify opportunities for plan sharing
3. Plan your migration strategy (per environment, per workload type, etc.)
4. Test in dev/test first
5. Monitor performance after migration
6. Adjust SKU or scaling settings as needed

## Questions?

See module READMEs:
- [app_service_plan/README.md](./app_service_plan/README.md)
- [linux_function_app/main.tf](./linux_function_app/main.tf)
- [windows_function_app/main.tf](./windows_function_app/main.tf)
- [logic_app_standard/main.tf](./logic_app_standard/main.tf)
- [linux_web_app/README.md](./linux_web_app/README.md)

