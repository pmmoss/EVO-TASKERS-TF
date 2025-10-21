# Shared State Migration Guide

## Overview

This guide documents the migration of Windows Function Apps and Logic Apps from individual application modules to the shared module. All function apps and logic apps are now deployed centrally in the `shared` module and referenced by application modules via remote state.

## What Changed

### Shared Module (`shared/`)

#### New Files Created:
- **`function_apps.tf`**: Defines all Windows Function Apps (automateddatafeed, autoopenshorex, dashboard, sendgridfunction, unlockbookings)
- **`logic_apps.tf`**: Defines all Logic Apps (unlockbookings-workflow)
- **`qa.tfvars`**: QA environment configuration for all apps
- **`prod.tfvars`**: Production environment configuration for all apps

#### Modified Files:
- **`variables.tf`**: Added application-specific variables for all five applications
- **`outputs.tf`**: Added outputs for all function apps and logic apps
- **`dev.tfvars`**: Added application configuration for all five applications

### Application Modules

All five application modules were updated:
1. **automateddatafeed/**
2. **autoopenshorex/**
3. **dashboard/**
4. **sendgridfunction/**
5. **unlockbookings/**

#### Changes Per Module:
- **`main.tf`**: Added `terraform_remote_state.shared` data source (if not already present)
- **`windows_function_app.tf`**: Replaced module call with reference comments
- **`logic_app_standard.tf`** (unlockbookings only): Replaced module call with reference comments
- **`outputs.tf`**: Updated to reference shared state outputs instead of local module outputs

## Architecture

### Before Migration
```
automateddatafeed/
├── windows_function_app.tf → Creates Function App
└── outputs.tf → Outputs from local module

unlockbookings/
├── windows_function_app.tf → Creates Function App
├── logic_app_standard.tf → Creates Logic App
└── outputs.tf → Outputs from local modules
```

### After Migration
```
shared/
├── function_apps.tf → Creates ALL Function Apps
├── logic_apps.tf → Creates ALL Logic Apps
└── outputs.tf → Outputs for all apps

automateddatafeed/
├── windows_function_app.tf → Reference comments only
└── outputs.tf → References shared state

unlockbookings/
├── windows_function_app.tf → Reference comments only
├── logic_app_standard.tf → Reference comments only
└── outputs.tf → References shared state
```

## Deployment Order

**CRITICAL**: The shared module MUST be deployed before any application modules.

### 1. Deploy Shared Module (First)

```bash
# For Dev environment
cd shared/
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# For QA environment
terraform plan -var-file="qa.tfvars"
terraform apply -var-file="qa.tfvars"

# For Production environment
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

### 2. Deploy Application Modules (After Shared)

Once the shared module is successfully deployed, you can deploy application modules:

```bash
# Example: Deploy automateddatafeed
cd ../automateddatafeed/
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## Configuration Management

### Shared Module Configuration

All application-specific settings are now configured in `shared/{env}.tfvars`:

```hcl
# Example from shared/dev.tfvars
automateddatafeed_enable_private_endpoint = false
automateddatafeed_additional_settings = {
  "ENVIRONMENT" = "Development"
  "name"        = "AutomatedDataFeed-Functions"
}
```

### Application Module Configuration

Application modules NO LONGER configure their function apps or logic apps directly. They only reference them via remote state.

The following variables are NO LONGER USED in application modules:
- ~~`function_app_sku`~~
- ~~`function_app_always_on`~~
- ~~`functions_worker_runtime`~~
- ~~`additional_function_app_settings`~~
- ~~`logic_app_storage_share_name`~~ (unlockbookings)
- ~~`use_extension_bundle`~~ (unlockbookings)
- ~~`bundle_version`~~ (unlockbookings)
- ~~`additional_logic_app_settings`~~ (unlockbookings)

These are now configured in the shared module.

## Available Outputs

### From Shared State

Each application can access the following outputs from shared state:

#### Function App Outputs
```hcl
# Example for automateddatafeed
data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_id
data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_name
data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_default_hostname
data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_identity_principal_id
```

#### Logic App Outputs (unlockbookings)
```hcl
data.terraform_remote_state.shared.outputs.unlockbookings_logic_app_id
data.terraform_remote_state.shared.outputs.unlockbookings_logic_app_name
data.terraform_remote_state.shared.outputs.unlockbookings_logic_app_default_hostname
data.terraform_remote_state.shared.outputs.unlockbookings_logic_app_identity_principal_id
```

## Migration Strategy

### Option 1: Fresh Deployment (Recommended for Dev)
1. Destroy existing application resources
2. Deploy shared module
3. Deploy application modules

```bash
# Destroy old resources
cd automateddatafeed/
terraform destroy -var-file="dev.tfvars"

# Deploy new architecture
cd ../shared/
terraform apply -var-file="dev.tfvars"

cd ../automateddatafeed/
terraform init -reconfigure  # Reconfigure backend if needed
terraform apply -var-file="dev.tfvars"
```

### Option 2: State Migration (Recommended for Prod)

Use `terraform state mv` to move resources from application state to shared state without destroying/recreating:

```bash
# 1. Import or move existing resources to shared state
cd shared/
terraform import 'module.automateddatafeed_function_app.azurerm_windows_function_app.main' /subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/...

# 2. Remove from old state
cd ../automateddatafeed/
terraform state rm 'module.windows_function_app'

# 3. Refresh application module
terraform refresh -var-file="prod.tfvars"
```

**Note**: State migration requires careful planning and should be tested in dev/qa first.

## Benefits of This Architecture

1. **Centralized Management**: All apps share the same service plans and are configured in one place
2. **Cost Optimization**: Apps share service plans instead of creating individual ones
3. **Consistency**: Uniform configuration across all applications
4. **Simplified Deployment**: Application modules focus on their specific resources
5. **Reduced Duplication**: DRY principle applied across modules

## Troubleshooting

### Error: "No outputs found"
**Cause**: Shared module not deployed or not applied successfully  
**Solution**: Deploy shared module first: `cd shared && terraform apply -var-file="dev.tfvars"`

### Error: "Resource already exists"
**Cause**: Resource exists in application state or Azure  
**Solution**: Use state migration (Option 2) or destroy and redeploy (Option 1)

### Function app settings not updating
**Cause**: Settings are now managed in shared module  
**Solution**: Update `shared/{env}.tfvars` and redeploy shared module

## Rollback Plan

If you need to rollback to the previous architecture:

1. Restore application module resource files from git history
2. Remove shared state data sources from application modules
3. Update outputs to reference local modules again
4. Redeploy application modules with local resources

```bash
git checkout HEAD~1 -- automateddatafeed/windows_function_app.tf
git checkout HEAD~1 -- automateddatafeed/outputs.tf
# Repeat for other modules
```

## Support

For questions or issues with the migration:
1. Review this guide thoroughly
2. Check deployment logs for specific errors
3. Verify shared module deployed successfully before deploying apps
4. Test in dev environment before migrating qa/prod

## Summary of Files Modified

### Shared Module
- ✅ Created: `function_apps.tf`
- ✅ Created: `logic_apps.tf`
- ✅ Created: `qa.tfvars`
- ✅ Created: `prod.tfvars`
- ✅ Modified: `variables.tf`
- ✅ Modified: `outputs.tf`
- ✅ Modified: `dev.tfvars`

### Application Modules (automateddatafeed, autoopenshorex, dashboard, sendgridfunction, unlockbookings)
- ✅ Modified: `main.tf` (added shared state reference)
- ✅ Modified: `windows_function_app.tf` (replaced with reference comments)
- ✅ Modified: `outputs.tf` (updated to use shared state)
- ✅ Modified: `logic_app_standard.tf` (unlockbookings only - replaced with reference comments)

---
**Last Updated**: $(date)  
**Migration Type**: Windows Function Apps and Logic Apps to Shared State

