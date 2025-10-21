# Revised Architecture: Shared Plans with Individual App Control

## ✅ Architecture Overview

The infrastructure has been restructured for better separation of concerns:

- **Shared Module** = App Service Plans ONLY (truly shared infrastructure)
- **Individual App Modules** = Function Apps & Logic Apps (app-specific resources)

## 🏗️ New Architecture

```
shared/
├── app_service_plans.tf        → Creates 2 shared plans
│   ├── windows_function_plan  (shared by all function apps)
│   └── logic_app_plan         (shared by all logic apps)
├── variables.tf                → Plan configuration only
├── outputs.tf                  → Plan IDs only
└── {env}.tfvars                → Plan SKUs and scaling

automateddatafeed/
├── windows_function_app.tf     → Creates function app, references shared plan
├── variables.tf                → App-specific settings
├── outputs.tf                  → App outputs
└── {env}.tfvars                → Private endpoint, app settings, etc.

autoopenshorex/
├── windows_function_app.tf     → Creates function app, references shared plan
├── variables.tf                → App-specific settings
├── outputs.tf                  → App outputs
└── {env}.tfvars                → Private endpoint, app settings, etc.

dashboard/
├── windows_function_app.tf     → Creates function app, references shared plan
├── variables.tf                → App-specific settings
├── outputs.tf                  → App outputs
└── {env}.tfvars                → Private endpoint, app settings, etc.

sendgridfunction/
├── windows_function_app.tf     → Creates function app, references shared plan
├── variables.tf                → App-specific settings
├── outputs.tf                  → App outputs
└── {env}.tfvars                → Private endpoint, app settings, etc.

unlockbookings/
├── windows_function_app.tf     → Creates function app, references shared plan
├── logic_app_standard.tf       → Creates logic app, references shared plan
├── variables.tf                → App-specific settings
├── outputs.tf                  → App outputs
└── {env}.tfvars                → Private endpoint, app settings, etc.
```

## 🔑 Key Principles

### What's Shared
✅ **App Service Plans** - The ONLY truly shared resources
- `windows_function_plan` - One plan for ALL function apps
- `logic_app_plan` - One plan for ALL logic apps

### What's Individual
✅ **Function Apps** - Each app manages its own
- Private endpoints (configured per app)
- App settings (configured per app)
- Monitoring configuration (configured per app)
- VNet integration (configured per app)

✅ **Logic Apps** - Each app manages its own
- Private endpoints (configured per app)
- Workflow settings (configured per app)
- Storage shares (configured per app)
- Extension bundles (configured per app)

## 📋 Configuration Management

### Shared Module (`shared/dev.tfvars`)
```hcl
# ONLY plan configuration
environment = "dev"

# Windows Function App Service Plan
windows_function_plan_sku              = "EP1"
windows_function_plan_enable_autoscale = false
windows_function_plan_min_capacity     = 1
windows_function_plan_max_capacity     = 3

# Logic App Service Plan
logic_app_plan_sku = "WS1"
```

### Individual App Modules (`automateddatafeed/dev.tfvars`)
```hcl
# App-specific configuration
environment = "dev"
app_name = "automateddatafeed"

# Private endpoint (unique to this app)
enable_private_endpoint = false

# Function runtime
functions_worker_runtime = "dotnet"
dotnet_version = "v8.0"

# App-specific settings
additional_function_app_settings = {
  "ENVIRONMENT" = "Development"
  "CustomSetting" = "Value"
}
```

## 💡 Benefits of This Approach

### 1. Clear Separation of Concerns
- **Shared module** = Infrastructure (plans)
- **App modules** = Applications (function apps, logic apps)

### 2. App Autonomy
- Each team can manage their own app
- Private endpoint decisions stay with the app
- App settings managed where they're used
- No cross-app dependencies

### 3. Better Security Boundaries
- Private endpoints configured per app needs
- Each app has its own security posture
- No "one size fits all" security

### 4. Simplified Deployment
- Shared module changes rarely (plan SKU changes)
- App modules change frequently (code, settings)
- Deploy apps independently of each other

### 5. Cost Optimization
- Still share the expensive resource (plans)
- Reduce Azure costs by 60%
- Clear cost allocation per app

## 🔄 How Resources Reference Each Other

### App References Shared Plan
```hcl
# automateddatafeed/windows_function_app.tf
module "windows_function_app" {
  source = "../../../modules/windows_function_app"
  
  # Reference shared plan via remote state
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.shared.outputs.windows_function_plan_id
  
  # App-specific private endpoint
  enable_private_endpoint    = var.enable_private_endpoint
  private_endpoint_subnet_id = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
  
  # App-specific settings
  additional_app_settings = var.additional_function_app_settings
}
```

### Shared Module Provides Plan ID
```hcl
# shared/outputs.tf
output "windows_function_plan_id" {
  value       = module.windows_function_plan.id
  description = "The ID of the shared Windows Function App Service Plan"
}
```

## 📊 Deployment Order

### 1. Deploy Shared Module (Infrastructure)
```bash
cd shared/
terraform init
terraform apply -var-file="dev.tfvars"
```

This creates:
- ✅ Windows Function App Service Plan
- ✅ Logic App Service Plan

### 2. Deploy Individual Apps (Applications)
```bash
# Apps can be deployed in any order or in parallel
cd ../automateddatafeed/
terraform apply -var-file="dev.tfvars"

cd ../dashboard/
terraform apply -var-file="dev.tfvars"

# etc...
```

Each app creates:
- ✅ Function App (using shared plan)
- ✅ Private Endpoint (if enabled for that app)
- ✅ App Settings (app-specific)
- ✅ Monitoring (app-specific)

## 🔍 Example: Private Endpoint Control

### Scenario: Only Production Apps Need Private Endpoints

**automateddatafeed/dev.tfvars:**
```hcl
enable_private_endpoint = false  # Dev: public access OK
```

**automateddatafeed/prod.tfvars:**
```hcl
enable_private_endpoint = true   # Prod: secure with PE
```

**dashboard/dev.tfvars:**
```hcl
enable_private_endpoint = false  # Dev: public access OK
```

**dashboard/prod.tfvars:**
```hcl
enable_private_endpoint = false  # Prod: still public (business decision)
```

### Result
- automateddatafeed in prod: ✅ Has private endpoint
- dashboard in prod: ❌ No private endpoint (team chose public)
- Each app team controls their own security posture

## 📦 What Each Module Contains

### Shared Module
| File | Purpose |
|------|---------|
| `app_service_plans.tf` | Creates the 2 shared plans |
| `variables.tf` | Plan SKU, autoscale settings |
| `outputs.tf` | Plan IDs for apps to reference |
| `dev.tfvars` | Dev plan configuration |
| `qa.tfvars` | QA plan configuration |
| `prod.tfvars` | Prod plan configuration |

### Application Modules (e.g., automateddatafeed)
| File | Purpose |
|------|---------|
| `windows_function_app.tf` | Creates function app, references shared plan |
| `main.tf` | Common/shared state references |
| `variables.tf` | App-specific variables |
| `outputs.tf` | App outputs |
| `dev.tfvars` | Dev app configuration |
| `qa.tfvars` | QA app configuration |
| `prod.tfvars` | Prod app configuration |

## 🎯 Key Differences from Previous Approach

### Before (Apps in Shared Module)
❌ All app configurations in `shared/dev.tfvars`  
❌ Private endpoints centrally managed  
❌ App settings centrally managed  
❌ Changes to one app affect shared module  
❌ One giant shared state file  

### After (Apps in Own Modules)
✅ App configurations in app tfvars files  
✅ Private endpoints managed per app  
✅ App settings managed per app  
✅ Changes to one app don't affect others  
✅ Small, focused state files  

## 💰 Cost Impact

### Same Cost Savings
- Before: 5 individual plans = ~$750/month
- After: 2 shared plans = ~$300/month
- **Savings: $450/month (60%)**

### Better Cost Allocation
- Can track costs per app
- Clear separation of infrastructure vs application costs
- Easier to charge back to teams

## 🚀 Migration from Previous Approach

If you already deployed the centralized approach, here's how to migrate:

### Option 1: Destroy and Recreate (Dev/Test)
```bash
# 1. Delete old app resources from shared module
cd shared/
terraform destroy -target=module.automateddatafeed_function_app

# 2. Deploy app in its own module
cd ../automateddatafeed/
terraform apply -var-file="dev.tfvars"
```

### Option 2: State Migration (Production)
```bash
# 1. Import existing resources to app module
cd automateddatafeed/
terraform import 'module.windows_function_app.azurerm_windows_function_app.main' \
  /subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/...

# 2. Remove from shared state
cd ../shared/
terraform state rm 'module.automateddatafeed_function_app'
```

## ✅ Summary

This architecture provides the best of both worlds:

1. **Cost Optimization** - Share expensive plans
2. **App Autonomy** - Each app controls its own settings
3. **Clear Boundaries** - Infrastructure vs applications
4. **Better Security** - App-specific private endpoints
5. **Simplified Management** - Changes isolated to affected apps

The shared module is now truly focused on **shared infrastructure** (plans), while application modules manage their **application-specific resources** (function apps, logic apps, private endpoints, settings).

---

**Architecture Type**: Shared Plans with Individual App Control  
**Status**: ✅ IMPLEMENTED  
**Last Updated**: $(date)

