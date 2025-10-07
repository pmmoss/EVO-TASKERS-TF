# Application Deployment Template

This guide shows how to create infrastructure for a new application (App Service or Function App) using the secure-by-default modules.

## Directory Structure

Each application gets its own directory under `project/evo-taskers/`:

```
project/evo-taskers/
├── common/                    # Shared infrastructure (VNet, Identity, etc.)
├── unlockbookings/           # Example: Function App
├── dashboard/                # Example: App Service (web app)
├── sendgridfunction/         # Example: Function App
└── your-new-app/             # Your new application
    ├── dev/
    │   ├── backend.tf         # Terraform state config
    │   ├── main.tf            # Remote state reference
    │   ├── app_service.tf     # App Service (if needed)
    │   ├── function_app.tf    # Function App (if needed)
    │   ├── variables.tf       # Input variables
    │   ├── outputs.tf         # Outputs
    │   └── terraform.tfvars   # Environment values
    ├── qa/
    └── prod/
```

## Resource Naming Pattern

With `app_name` parameter, resources are uniquely named:

| Resource | Pattern | Example (unlockbookings) |
|----------|---------|--------------------------|
| App Service Plan (Web) | `asp-{project}-{env}-{location_short}-{app_name}` | `asp-pmoss-evotaskers-dev-wus2-unlockbookings` |
| App Service Plan (Func) | `asp-{project}-{env}-{location_short}-{app_name}-func` | `asp-pmoss-evotaskers-dev-wus2-unlockbookings-func` |
| Web App | `app-{project}-{env}-{location_short}-{app_name}` | `app-pmoss-evotaskers-dev-wus2-unlockbookings` |
| Function App | `fa-{project}-{env}-{location_short}-{app_name}` | `fa-pmoss-evotaskers-dev-wus2-unlockbookings` |

This ensures **no naming conflicts** between applications!

## Creating a New Application

### Step 1: Copy Template

```bash
# Copy the unlockbookings folder as a template
cp -r project/evo-taskers/unlockbookings project/evo-taskers/your-app-name

cd project/evo-taskers/your-app-name/dev
```

### Step 2: Update Backend Configuration

Edit `backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "apps/your-app-name-dev.tfstate"  # ← Change this
  }
}
```

### Step 3: Configure Application Type

Choose what you need:

#### Option A: Function App Only (like UnlockBookings)

Keep `function_app.tf` uncommented, comment out `app_service.tf`:

```hcl
# app_service.tf - comment out entire module
# module "app_service" {
#   ...
# }

# function_app.tf - keep uncommented
module "function_app" {
  source = "../../../../modules/function_app"
  
  app_name = "your-app-name"  # ← Change to your app name
  
  # ... rest stays the same (references common infrastructure)
}
```

#### Option B: App Service Only (for web apps)

Keep `app_service.tf` uncommented, comment out `function_app.tf`:

```hcl
# app_service.tf - keep uncommented
module "app_service" {
  source = "../../../../modules/app_service"
  
  app_name = "your-app-name"  # ← Change to your app name
  
  # ... rest stays the same
}

# function_app.tf - comment out entire module
# module "function_app" {
#   ...
# }
```

#### Option C: Both App Service and Function App

Keep both uncommented with the same `app_name`:

```hcl
# Both modules use the same app_name for related resources
module "app_service" {
  app_name = "your-app-name"
  # ...
}

module "function_app" {
  app_name = "your-app-name"
  # ...
}
```

### Step 4: Update terraform.tfvars

Edit `terraform.tfvars`:

```hcl
# App Service Configuration (if using App Service)
app_service_sku       = "B1"     # B1, S1, P1V2
app_service_always_on = false    # true for production

# Function App Configuration (if using Function App)
function_app_sku         = "B1"    # B1, EP1, Y1
function_app_always_on   = false
functions_worker_runtime = "dotnet"  # dotnet, node, python, java

# Runtime
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Network
enable_private_endpoint = false  # true for production

# Custom settings for your app
additional_app_settings = {
  # Your app-specific settings here
}
```

### Step 5: Update Outputs

Edit `outputs.tf` to match what you're deploying:

**For Function App only**:
```hcl
# Comment out app_service outputs
# output "app_service_id" { ... }

# Keep function_app outputs
output "function_app_id" {
  value = module.function_app.function_app_id
}
```

**For App Service only**:
```hcl
# Keep app_service outputs
output "app_service_id" {
  value = module.app_service.app_service_id
}

# Comment out function_app outputs
# output "function_app_id" { ... }
```

### Step 6: Deploy

```bash
terraform init
terraform plan
terraform apply
```

## What Each Application Gets (Automatically)

✅ **User-Assigned Managed Identity** (from common infrastructure)  
✅ **VNet Integration** (outbound traffic through private network)  
✅ **Application Insights** (monitoring & diagnostics)  
✅ **Key Vault Access** (via managed identity RBAC)  
✅ **Storage Access** (via managed identity RBAC)  
✅ **Diagnostic Logging** (to Log Analytics)  
✅ **Secure Defaults** (HTTPS only, TLS 1.2, FTP disabled)  
✅ **Azure DevOps Ready** (configured for pipeline deployments)  

## Application Examples

### Dashboard (App Service)

```
dashboard/
└── dev/
    ├── app_service.tf    ← Uncommented (app_name = "dashboard")
    ├── function_app.tf   ← Commented out
    └── terraform.tfvars
```

Result: `app-pmoss-evotaskers-dev-wus2-dashboard`

### SendGrid Function (Function App)

```
sendgridfunction/
└── dev/
    ├── app_service.tf    ← Commented out
    ├── function_app.tf   ← Uncommented (app_name = "sendgridfunction")
    └── terraform.tfvars
```

Result: `fa-pmoss-evotaskers-dev-wus2-sendgridfunction`

### AutomatedDataFeed (Both)

```
automateddatafeed/
└── dev/
    ├── app_service.tf    ← Uncommented (app_name = "datafeed")
    ├── function_app.tf   ← Uncommented (app_name = "datafeed")
    └── terraform.tfvars
```

Results:
- `app-pmoss-evotaskers-dev-wus2-datafeed`
- `fa-pmoss-evotaskers-dev-wus2-datafeed`

## Important Notes

### App Name Convention

Use lowercase, no spaces, descriptive names:
- ✅ `unlockbookings`
- ✅ `dashboard`
- ✅ `sendgrid`
- ✅ `datafeed`
- ❌ `UnlockBookings` (avoid uppercase)
- ❌ `my-app` (avoid hyphens, use lowercase letters only)

### Shared Resources

All applications share:
- Same VNet and subnets
- Same user-assigned managed identity
- Same Key Vault
- Same Application Insights
- Same Storage Account

This is **by design** - it simplifies security and reduces costs.

### Independent Deployments

Each application can be deployed/destroyed independently without affecting others:

```bash
# Deploy unlockbookings
cd unlockbookings/dev
terraform apply

# Deploy dashboard (won't affect unlockbookings)
cd ../../dashboard/dev
terraform apply
```

### State Management

Each application has its own state file:
- `apps/unlockbookings-dev.tfstate`
- `apps/dashboard-dev.tfstate`
- `apps/sendgridfunction-dev.tfstate`

This allows independent deployments and team collaboration.

## Azure DevOps Pipeline

Each app gets its own pipeline. Example for your app:

```yaml
trigger:
  branches:
    include:
    - develop
  paths:
    include:
    - src/YourApp/*

variables:
  azureSubscription: 'Your-Service-Connection'
  # Get these from: terraform output
  appServiceName: 'app-pmoss-evotaskers-dev-wus2-yourapp'
  # OR for Function App:
  functionAppName: 'fa-pmoss-evotaskers-dev-wus2-yourapp'

stages:
- stage: Deploy
  jobs:
  - job: DeployApp
    steps:
    # For App Service:
    - task: AzureWebApp@1
      inputs:
        azureSubscription: '$(azureSubscription)'
        appType: 'webAppLinux'
        appName: '$(appServiceName)'
        package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    
    # For Function App:
    - task: AzureFunctionApp@1
      inputs:
        azureSubscription: '$(azureSubscription)'
        appType: 'functionAppLinux'
        appName: '$(functionAppName)'
        package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
```

## SKU Recommendations

### Development

| Type | SKU | Cost | Best For |
|------|-----|------|----------|
| App Service | B1 | ~$13/month | Web apps, APIs |
| Function App | B1 | ~$13/month | Scheduled jobs, background tasks |
| Function App | Y1 | Pay-per-use | Infrequent executions |

### Production

| Type | SKU | Cost | Best For |
|------|-----|------|----------|
| App Service | P1V2 | ~$73/month | Production web apps |
| Function App | EP1 | ~$146/month | Production functions (no cold start) |

## Security Checklist

For each new application, verify:

- ✅ `app_name` parameter is set correctly
- ✅ Uses user-assigned identity from common infrastructure
- ✅ VNet integration enabled (`enable_vnet_integration = true`)
- ✅ Application Insights configured
- ✅ Key Vault URI configured
- ✅ HTTPS only enabled (default)
- ✅ TLS 1.2 minimum (default)
- ✅ For production: `enable_private_endpoint = true`

## Troubleshooting

### Name Already Exists

If you get "resource already exists", another app might be using that name. Check:

```bash
# List all apps in the resource group
az webapp list --resource-group rg-pmoss-evotaskers-dev-wus2 --query "[].name" -o table
az functionapp list --resource-group rg-pmoss-evotaskers-dev-wus2 --query "[].name" -o table
```

Use a different `app_name`.

### Can't Access Key Vault

Verify the managed identity has access (should be automatic from common infrastructure):

```bash
cd ../common/dev
terraform output workload_identity_principal_id
```

Check RBAC in Azure Portal → Key Vault → Access control (IAM).

### Function App Won't Start

1. Verify storage account is accessible
2. Check Application Insights connection
3. Review function app logs in Azure Portal

## Next Steps

1. **Deploy your application code** via Azure DevOps
2. **Add secrets to Key Vault** (not in code!)
3. **Configure custom domain** (for production)
4. **Set up auto-scaling** (for production)
5. **Enable deployment slots** (for production)

## Support

- Module Documentation: `/modules/{app_service|function_app}/README.md`
- UnlockBookings Example: `unlockbookings/dev/`
- Common Infrastructure: `common/dev/`

---

**Template Version**: 1.0  
**Last Updated**: October 2025

