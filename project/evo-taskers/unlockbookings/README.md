# UnlockBookings Application Infrastructure

This directory contains Terraform configurations for deploying the UnlockBookings application across multiple environments (dev, qa, prod).

## 📁 Directory Structure

```
unlockbookings/
├── README.md              ← This file (overview & configuration guide)
├── DEPLOYMENT-GUIDE.md    ← Detailed deployment procedures
├── main.tf               ← Shared: Data sources & locals
├── variables.tf          ← Shared: Variable definitions
├── outputs.tf           ← Shared: Output definitions
├── app_service.tf       ← Shared: App Service module (commented out)
├── function_app.tf      ← Shared: Function App module (active)
├── dev/
│   ├── backend.tf       ← Dev-specific backend state
│   ├── terraform.tfvars ← Dev-specific values
│   └── *.tf → ../*.tf   ← Symlinks to shared configs
├── qa/
│   ├── backend.tf       ← QA-specific backend state
│   ├── terraform.tfvars ← QA-specific values
│   └── *.tf → ../*.tf   ← Symlinks to shared configs
└── prod/
    ├── backend.tf       ← Prod-specific backend state
    ├── terraform.tfvars ← Prod-specific values
    └── *.tf → ../*.tf   ← Symlinks to shared configs
```

## 🏗️ Architecture

### Two-Tier Deployment Model

**Tier 1: Common Infrastructure** (Shared per environment)
- Virtual Network & Subnets
- User-Assigned Managed Identity
- Key Vault
- Application Insights
- Log Analytics Workspace
- Storage Account
- Bastion (optional)

**Tier 2: Application Infrastructure** (This directory)
- Function App (Linux .NET 8.0)
- App Service (optional, currently disabled)
- Private Endpoints
- Diagnostic Settings

```
┌─────────────────────────────────────────┐
│       Common Infrastructure             │
│  (Deployed once per environment)        │
│                                         │
│  • VNet & Subnets                      │
│  • Managed Identity                    │
│  • Key Vault                           │
│  • App Insights                        │
│  • Storage Account                     │
└──────────────┬──────────────────────────┘
               │
               │ Remote State Reference
               │
┌──────────────▼──────────────────────────┐
│     UnlockBookings Application          │
│  (Can be deployed independently)        │
│                                         │
│  • Function App (Linux .NET 8.0)       │
│  • VNet Integrated                     │
│  • Private Endpoints                   │
│  • Secure by default                   │
└─────────────────────────────────────────┘
```

## 🚀 Quick Start

### Deploy to Dev

```bash
cd project/evo-taskers/unlockbookings/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Deploy to QA or Production

```bash
cd project/evo-taskers/unlockbookings/{qa|prod}
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## 🔑 Key Concepts

### Shared Configuration Files

All `.tf` files are at the root level and shared across environments:
- **main.tf** - References common infrastructure via remote state
- **variables.tf** - Defines all variables with defaults
- **outputs.tf** - Exposes resource information
- **function_app.tf** - Configures the Function App module

### Environment-Specific Files

Each environment directory contains only:
- **backend.tf** - Terraform backend state configuration
- **terraform.tfvars** - Environment-specific variable values

### How It Works

When you run `terraform plan` from `dev/`:
1. Reads `dev/backend.tf` (state configuration)
2. Reads `dev/terraform.tfvars` (sets `environment = "dev"`)
3. Reads symlinked `.tf` files (pointing to shared parent configuration)
4. Dynamically references `evo-taskers-common-dev.tfstate` based on environment variable

**Note:** Each environment directory contains **symlinks** to the shared `.tf` files at the parent level. This maintains a single source of truth while allowing Terraform to run from each environment directory.

## ⚙️ Configuration

### Environment Variable (Required)

Each environment must set the `environment` variable in `terraform.tfvars`:

```hcl
# dev/terraform.tfvars
environment = "dev"

# qa/terraform.tfvars
environment = "qa"

# prod/terraform.tfvars
environment = "prod"
```

This variable:
- ✅ Validated to only allow: `dev`, `qa`, `prod`
- ✅ Determines which common infrastructure state to reference
- ✅ Used in resource naming and tagging

### Function App Configuration

Key settings in `terraform.tfvars`:

```hcl
# SKU Configuration
function_app_sku         = "P0v3"  # or "EP1" for premium
function_app_always_on   = false   # Set true for prod
functions_worker_runtime = "dotnet"

# Network Security
enable_private_endpoint = true  # Disable public access

# Application Settings
additional_function_app_settings = {
  name = "UnlockBookings-Functions"
  # Add custom settings here
}
```

### Storage Configuration

#### Default (Access Key - Currently Active)

The module automatically configures storage using access keys from common infrastructure:

```hcl
# In function_app.tf (automatic)
storage_account_name       = data.terraform_remote_state.common.outputs.storage_account_name
storage_account_access_key = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
```

**Status:** ✅ Working out of the box  
**Best for:** Dev/QA environments

#### Enhanced (Managed Identity - Recommended for Production)

For better security, use managed identity instead of access keys:

```hcl
# In terraform.tfvars
additional_function_app_settings = {
  "AzureWebJobsStorage__accountName" = "stevotaskersprodeus"
  "AzureWebJobsStorage__credential"  = "managedidentity"
}
```

**Benefits:**
- 🔐 No storage keys exposed
- 🔄 Automatic key rotation
- ✅ Azure AD authentication
- 📊 Better audit trail

**Requirements:**
- Managed identity must have "Storage Blob Data Contributor" role (already configured)
- Storage account must allow managed identity access

#### Custom Storage Accounts

If you need additional storage accounts:

```hcl
additional_function_app_settings = {
  "CustomStorage__serviceUri" = "https://myappstorage.blob.core.windows.net"
  "CustomStorage__credential" = "managedidentity"
}
```

### Storage Bindings

Configure storage connections for triggers and bindings:

```hcl
# Blob Storage
"BlobStorageConnection__serviceUri" = "https://storage.blob.core.windows.net"
"BlobStorageConnection__credential" = "managedidentity"

# Queue Storage
"QueueStorageConnection__queueServiceUri" = "https://storage.queue.core.windows.net"
"QueueStorageConnection__credential"      = "managedidentity"

# Table Storage
"TableStorageConnection__tableServiceUri" = "https://storage.table.core.windows.net"
"TableStorageConnection__credential"      = "managedidentity"
```

## 🔒 Security Features

### Network Security
- ✅ VNet Integration (outbound traffic through VNet)
- ✅ Private Endpoints (optional, blocks public access)
- ✅ TLS 1.2 minimum
- ✅ HTTPS only
- ✅ FTP disabled

### Identity & Access
- ✅ User-Assigned Managed Identity
- ✅ Azure AD authentication
- ✅ RBAC on Key Vault and Storage
- ✅ No hardcoded credentials

### Monitoring & Compliance
- ✅ Application Insights integration
- ✅ Diagnostic logs to Log Analytics
- ✅ Metric collection enabled
- ✅ Audit trail for all operations

## 🌍 Environment Differences

| Setting | Dev | QA | Production |
|---------|-----|-----|------------|
| SKU | P0v3 | P0v3 | EP1 (Premium) |
| Always On | false | true | true |
| Private Endpoint | true | true | true (required) |
| Storage Auth | Access Key | Access Key | Managed Identity (recommended) |

## 📝 Common Tasks

### Change All Environments

Edit shared files at root:
```bash
vim unlockbookings/function_app.tf
# Then apply to each environment
```

### Change One Environment

Edit that environment's `terraform.tfvars`:
```bash
vim unlockbookings/dev/terraform.tfvars
cd unlockbookings/dev
terraform apply
```

### Compare Environments

```bash
diff dev/terraform.tfvars qa/terraform.tfvars
diff qa/terraform.tfvars prod/terraform.tfvars
```

### Add Environment-Specific Setting

```hcl
# In dev/terraform.tfvars
additional_function_app_settings = {
  name = "UnlockBookings-Functions"
  "MyDevOnlySetting" = "dev-value"
}
```

### Migrate to Managed Identity

**Step 1: Test in Dev**
```hcl
# dev/terraform.tfvars
additional_function_app_settings = {
  "AzureWebJobsStorage__accountName" = "stevotaskersdeveus"
  "AzureWebJobsStorage__credential"  = "managedidentity"
}
```

**Step 2: Deploy and Verify**
```bash
cd dev
terraform apply
# Test function app thoroughly
```

**Step 3: Promote to QA, then Production**

## 🔍 Troubleshooting

### Issue: Module Not Found

**Cause:** Running from wrong directory  
**Solution:** Always run from environment directory (`dev/`, `qa/`, `prod/`)

### Issue: Variable Not Defined

**Cause:** Missing `environment` in terraform.tfvars  
**Solution:** Add `environment = "dev"` to your tfvars

### Issue: Backend Initialization Failed

**Cause:** `backend.tf` not in current directory  
**Solution:** Ensure you're in environment directory

### Issue: Storage Access Denied

**Cause:** Network or permission issue  
**Solution:**
1. Verify VNet integration is enabled
2. Check subnet has access to storage private endpoint
3. Confirm managed identity has "Storage Blob Data Contributor" role
4. Check storage firewall rules

### Issue: Can't Access Common State

**Cause:** Wrong state key or environment value  
**Solution:**
1. Verify `environment` variable in tfvars
2. Check common infrastructure is deployed for that environment
3. Verify state file exists in Azure Storage

## 📊 State Files

Each environment has separate state files:

```
Azure Storage Container: tfstate
├── landing-zone/
│   ├── evo-taskers-common-dev.tfstate        ← Common infra (dev)
│   ├── evo-taskers-unlockbookings-dev.tfstate   ← This app (dev)
│   ├── evo-taskers-common-qa.tfstate         ← Common infra (qa)
│   ├── evo-taskers-unlockbookings-qa.tfstate    ← This app (qa)
│   ├── evo-taskers-common-prod.tfstate       ← Common infra (prod)
│   └── evo-taskers-unlockbookings-prod.tfstate  ← This app (prod)
```

## 🎯 Best Practices

1. ✅ **Run from environment directories** - Always `cd` to `dev/`, `qa/`, or `prod/`
2. ✅ **Review plans before applying** - Use `terraform plan -out=tfplan`
3. ✅ **Test in dev first** - Never test changes directly in production
4. ✅ **Use managed identity in prod** - More secure than access keys
5. ✅ **Enable private endpoints** - Restrict public access
6. ✅ **Document custom settings** - Comment why settings exist
7. ✅ **Keep environments consistent** - Only vary what's necessary

## 🔄 Workflow

### Development → QA → Production

```bash
# 1. Make changes to shared config
vim unlockbookings/function_app.tf

# 2. Test in dev
cd unlockbookings/dev
terraform plan
terraform apply tfplan

# 3. Verify in dev
# Run tests, check logs, validate functionality

# 4. Promote to QA
cd ../qa
terraform plan
terraform apply tfplan

# 5. Verify in QA
# Run integration tests

# 6. Promote to production
cd ../prod
terraform plan
terraform apply tfplan
```

## 📚 Additional Resources

- **DEPLOYMENT-GUIDE.md** - Comprehensive deployment procedures with pre-checks and rollback
- **Azure Functions Documentation** - https://learn.microsoft.com/en-us/azure/azure-functions/
- **Terraform Azure Provider** - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

## 🆘 Getting Help

1. Review error messages carefully
2. Check terraform plan output before applying
3. Verify you're in correct directory
4. Ensure common infrastructure is deployed
5. Check Azure Portal for resource status
6. Review Application Insights for runtime issues

## 📋 Outputs

After deployment, Terraform outputs:

```hcl
function_app_id               # Resource ID
function_app_name             # Function App name
function_app_default_hostname # FQDN (e.g., fa-evotaskers-dev.azurewebsites.net)
function_app_url             # HTTPS URL
function_app_service_plan_id # App Service Plan ID
```

Access outputs:
```bash
terraform output function_app_url
```

## 🔐 Security Recommendations

### Development
- ✅ Use access keys (simpler, already configured)
- ✅ Enable VNet integration
- ⚠️ Private endpoints optional

### QA
- ✅ Consider managed identity
- ✅ Enable VNet integration
- ✅ Enable private endpoints

### Production
- ✅ Use managed identity (required)
- ✅ Enable VNet integration (required)
- ✅ Enable private endpoints (required)
- ✅ Review all security settings
- ✅ Enable all diagnostic logging

---

**Need more details?** See `DEPLOYMENT-GUIDE.md` for comprehensive deployment procedures, pre-deployment checks, and troubleshooting.
