# App Service Plan Refactoring - Summary

## What Was Done

Successfully refactored the Terraform modules to separate App Service Plans from app resources (Function Apps, Logic Apps, Web Apps), enabling cost optimization through plan sharing while maintaining backward compatibility.

## Changes Made

### 1. New Module Created ✨

**`app_service_plan/`** - Dedicated module for creating standalone App Service Plans

- **Files Created:**
  - `main.tf` - Resource definitions with autoscaling support
  - `variables.tf` - Input variables for plan configuration
  - `outputs.tf` - Outputs including plan ID, name, SKU, etc.
  - `README.md` - Comprehensive documentation

- **Features:**
  - Support for both Windows and Linux OS types
  - Flexible SKU configuration (Consumption, Premium, Standard, etc.)
  - Optional autoscaling with CPU and memory-based rules
  - Zone redundancy support (Premium SKUs)
  - Per-site scaling capability
  - Custom naming or convention-based naming

### 2. Updated Existing Modules 🔄

#### `linux_function_app/`
- **Modified:** `main.tf`, `variables.tf`, `outputs.tf`
- **Changes:**
  - Made App Service Plan creation optional (conditional with `count`)
  - Added `create_service_plan` variable (default: `true`)
  - Added `existing_service_plan_id` variable (default: `null`)
  - Updated `service_plan_id` reference to support both modes
  - Updated outputs to handle conditional plan

#### `windows_function_app/`
- **Modified:** `main.tf`, `variables.tf`, `outputs.tf`
- **Changes:**
  - Made App Service Plan creation optional (conditional with `count`)
  - Added `create_service_plan` variable (default: `true`)
  - Added `existing_service_plan_id` variable (default: `null`)
  - Updated `service_plan_id` reference to support both modes
  - Updated outputs to handle conditional plan

#### `logic_app_standard/`
- **Modified:** `main.tf`, `variables.tf`, `outputs.tf`
- **Changes:**
  - Made App Service Plan creation optional (conditional with `count`)
  - Added `create_service_plan` variable (default: `true`)
  - Added `existing_service_plan_id` variable (default: `null`)
  - Updated `app_service_plan_id` reference to support both modes
  - Updated outputs to handle conditional plan

#### `linux_web_app/`
- **No changes needed** - Already had this pattern implemented! ✅

### 3. Documentation Created 📚

- **`MIGRATION-GUIDE.md`** - Comprehensive guide covering:
  - Migration options (backward compatible vs. shared plans)
  - Common patterns and use cases
  - Cost optimization strategies
  - Rollback procedures
  - Troubleshooting guide
  - Best practices

- **`QUICK-REFERENCE.md`** - Quick lookup guide with:
  - Before/after code examples
  - Ready-to-use snippets
  - Common scenarios
  - Variable cheat sheet
  - SKU reference table
  - Troubleshooting quick fixes

- **`modules/app_service_plan/README.md`** - Full module documentation with:
  - Usage examples
  - Input/output reference
  - SKU recommendations
  - Plan sharing examples

## Key Features

### ✅ Backward Compatibility

**No breaking changes!** Existing configurations work without modifications:

```hcl
# This still works exactly as before
module "my_function" {
  source = "./modules/windows_function_app"
  
  app_name = "myapp"
  sku_name = "EP1"
  # ... existing config
}
```

### 💰 Cost Optimization

Share plans across multiple apps to reduce costs:

**Before:** 3 apps × 3 plans × $150/mo = **$450/month**

**After:** 3 apps × 1 plan × $150/mo = **$150/month** (saves $300/mo)

```hcl
# One shared plan
module "shared_plan" {
  source = "./modules/app_service_plan"
  sku_name = "EP1"
  # ...
}

# Multiple apps use it
module "app1" {
  source = "./modules/windows_function_app"
  create_service_plan      = false
  existing_service_plan_id = module.shared_plan.id
  # ...
}
module "app2" { ... same ... }
module "app3" { ... same ... }
```

### 🔧 Flexibility

Choose the best strategy per environment, workload, or app:

```hcl
# Dev: Individual consumption plans (cheapest)
module "dev_func" {
  source   = "./modules/windows_function_app"
  sku_name = "Y1"  # Pay per execution
}

# Prod: Shared premium plan with autoscaling
module "prod_plan" {
  source = "./modules/app_service_plan"
  sku_name             = "EP2"
  enable_autoscale     = true
  autoscale_max_capacity = 10
}
```

### 🏗️ Modular Architecture

Separate concerns for better infrastructure management:

```
Common Infrastructure (common/)
  └─ Shared App Service Plans
  
Individual Apps (dashboard/, sendgrid/, etc.)
  └─ Apps reference shared plans
  └─ Or create their own (isolated)
```

## New Variables in App Modules

All function app and logic app modules now support:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_service_plan` | `bool` | `true` | Create new plan or use existing |
| `existing_service_plan_id` | `string` | `null` | ID of existing plan (required if `create_service_plan = false`) |
| `sku_name` | `string` | varies | SKU for plan (only used if `create_service_plan = true`) |

## Migration Paths

### Option 1: No Migration (Keep Current Behavior)
- **Action:** Do nothing
- **Result:** Each app continues to have its own plan
- **Best for:** Apps with unique scaling requirements

### Option 2: Gradual Migration
- **Action:** Migrate one environment at a time (dev → qa → prod)
- **Result:** Shared plans in selected environments
- **Best for:** Risk-averse approach, validate before full migration

### Option 3: Full Migration
- **Action:** Create shared plans, update all apps to use them
- **Result:** Maximum cost savings
- **Best for:** Apps with similar scaling patterns

## Example: EVO-TASKERS Migration

### Current State (Before)
```
dashboard/          → Creates own EP1 plan
sendgrid/           → Creates own EP1 plan
autoopenshorex/     → Creates own EP1 plan
automateddatafeed/  → Creates own EP1 plan
unlockbookings/     → Creates own WS1 plan

Cost: 4 × $150 + 1 × $225 = $825/month
```

### Proposed State (After)
```
common/
  ├─ Shared Windows Function Plan (EP2) → dashboard, sendgrid, autoopenshorex, automateddatafeed
  └─ Shared Logic App Plan (WS1)        → unlockbookings

Cost: $300 (EP2) + $225 (WS1) = $525/month

Savings: $300/month or 36%
```

### Implementation Steps

1. **In `common/main.tf`, add shared plans:**
```hcl
module "shared_function_plan" {
  source = "../../../modules/app_service_plan"
  
  project    = var.project
  plan_name  = "shared-functions"
  environment = var.environment
  # ... config
  
  os_type  = "Windows"
  sku_name = "EP2"  # One tier up to handle 4 apps
  
  enable_autoscale       = true
  autoscale_min_capacity = 1
  autoscale_max_capacity = 5
}

module "shared_logic_app_plan" {
  source = "../../../modules/app_service_plan"
  
  project    = var.project
  plan_name  = "logicapps"
  environment = var.environment
  # ... config
  
  os_type  = "Windows"
  sku_name = "WS1"
}

output "shared_function_plan_id" {
  value = module.shared_function_plan.id
}

output "shared_logic_app_plan_id" {
  value = module.shared_logic_app_plan.id
}
```

2. **Update each function app (dashboard, sendgrid, etc.):**
```hcl
data "terraform_remote_state" "common" {
  backend = "azurerm"
  config = {
    # ... backend config
  }
}

module "dashboard_function" {
  source = "../../../modules/windows_function_app"
  
  # Switch to shared plan
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.common.outputs.shared_function_plan_id
  
  # Remove: sku_name (no longer needed)
  
  # Keep everything else the same
  app_name = "dashboard"
  # ...
}
```

3. **Update unlockbookings logic app:**
```hcl
module "unlockbookings_logic_app" {
  source = "../../../modules/logic_app_standard"
  
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.common.outputs.shared_logic_app_plan_id
  
  app_name = "unlockbookings"
  # ...
}
```

## Testing Checklist

Before applying changes:

- [ ] Review MIGRATION-GUIDE.md for your use case
- [ ] Test in dev environment first
- [ ] Verify plan SKU can handle expected load
- [ ] Ensure OS types match (Windows app → Windows plan)
- [ ] Check remote state configuration if using data sources
- [ ] Plan Terraform changes (`terraform plan`)
- [ ] Review plan output for unexpected changes

After applying:

- [ ] Verify apps are running correctly
- [ ] Check App Service Plan metrics (CPU, memory)
- [ ] Monitor app performance
- [ ] Verify autoscaling works (if enabled)
- [ ] Test app functionality end-to-end

## Rollback

If needed, rollback is simple:

```hcl
module "my_function" {
  source = "./modules/windows_function_app"
  
  create_service_plan = true   # Change from false to true
  sku_name           = "EP1"   # Add SKU back
  # existing_service_plan_id = ...  # Remove this line
  
  # Rest stays the same
}
```

## Next Steps

1. **Read the documentation:**
   - [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) - Detailed migration guide
   - [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick lookup examples
   - [app_service_plan/README.md](./app_service_plan/README.md) - Module docs

2. **Plan your migration:**
   - Identify which apps can share plans
   - Determine appropriate SKUs
   - Choose migration strategy (gradual vs. full)

3. **Start with dev:**
   - Implement shared plans in dev first
   - Validate functionality and performance
   - Monitor for a few days

4. **Proceed to production:**
   - Apply same patterns to QA and prod
   - Enable autoscaling for variable workloads
   - Monitor costs and performance

## Benefits Summary

✅ **Cost Savings** - Share plans across multiple apps  
✅ **Flexibility** - Choose per app, per workload, or per environment  
✅ **Backward Compatible** - No breaking changes  
✅ **Better Organization** - Separate infrastructure from app config  
✅ **Scalability** - Autoscaling support built-in  
✅ **High Availability** - Zone redundancy support  
✅ **Well Documented** - Comprehensive guides and examples  

## Support

For issues or questions:
1. Check [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) troubleshooting section
2. Review [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for examples
3. See module-specific READMEs for detailed docs

---

**Status:** ✅ Complete and ready to use  
**Backward Compatible:** ✅ Yes  
**Breaking Changes:** ❌ None  
**Documentation:** ✅ Complete  
**Testing Required:** ✅ Yes (dev first)

