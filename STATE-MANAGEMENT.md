# Terraform State Management Quick Reference

## 🎯 State File Strategy

We use **separate state files** to isolate concerns and enable independent deployments:

| State File | Purpose | Managed By | Contains |
|------------|---------|-------------|----------|
| `landing-zone/global.tfstate` | Core Infrastructure | Platform Team | VNET, Key Vault, Storage, Log Analytics, Bastion |
| `applications/{app}/{env}.tfstate` | Application Resources | App Teams | App Services, Databases, App-specific resources |

## 🚀 Quick Start Commands

### 1. Setup State Storage (One-time)
```bash
# Run the setup script
./scripts/setup-terraform-state.sh

# Or manually create storage account
az group create --name rg-terraform-state --location "West US 2"
az storage account create --name stterraformstate --resource-group rg-terraform-state --location "West US 2" --sku Standard_LRS
az storage container create --name tfstate --account-name stterraformstate
```

### 2. Deploy Landing Zone
```bash
cd global
terraform init
terraform plan
terraform apply
```

### 3. Deploy Application
```bash
# Create app directory
mkdir -p applications/myapp
cd applications/myapp

# Copy backend template
cp ../../backend-app.tf.example backend.tf
# Edit backend.tf: key = "applications/myapp/dev.tfstate"

# Create app configuration
# (Copy from examples or create your own)

# Deploy
terraform init
terraform apply
```

## 📁 Directory Structure

```
evo-taskers-tf-new/
├── global/                          # Landing Zone
│   ├── backend.tf                   # State: landing-zone/global.tfstate
│   ├── terraform.tfvars            # Global configuration
│   └── main.tf                      # Core infrastructure
├── applications/                     # Applications
│   └── myapp/                       # Your application
│       ├── backend.tf               # State: applications/myapp/dev.tfstate
│       ├── main.tf                  # App-specific resources
│       └── terraform.tfvars         # App configuration
├── backend-app.tf.example           # Template for app backends
└── scripts/
    └── setup-terraform-state.sh    # State storage setup
```

## 🔧 Backend Configurations

### Landing Zone Backend (`global/backend.tf`)
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "landing-zone/global.tfstate"
  }
}
```

### Application Backend (`applications/myapp/backend.tf`)
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "applications/myapp/dev.tfstate"
  }
}
```

## 🔄 Common Operations

### Switch Between Environments
```bash
# Landing Zone
cd global
terraform init
terraform plan

# Application Dev
cd applications/myapp
# Update backend.tf key to "applications/myapp/dev.tfstate"
terraform init -reconfigure
terraform plan

# Application Prod
cd applications/myapp
# Update backend.tf key to "applications/myapp/prod.tfstate"
terraform init -reconfigure
terraform plan
```

### View State Contents
```bash
# Landing Zone state
cd global
terraform state list

# Application state
cd applications/myapp
terraform state list
```

### Import Existing Resources
```bash
# Into landing zone
cd global
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/example

# Into application
cd applications/myapp
terraform import azurerm_linux_web_app.example /subscriptions/.../sites/example
```

### Move Resources Between States
```bash
# Remove from landing zone
cd global
terraform state rm azurerm_linux_web_app.example

# Add to application
cd applications/myapp
terraform import azurerm_linux_web_app.example /subscriptions/.../sites/example
```

## 🚨 Troubleshooting

### State Lock Issues
```bash
# Check for locks
terraform force-unlock <lock-id>

# Or wait for timeout (default 5 minutes)
```

### Backend Configuration Issues
```bash
# Reconfigure backend
terraform init -reconfigure

# Or remove .terraform directory and reinit
rm -rf .terraform
terraform init
```

### State File Corruption
```bash
# Restore from backup
az storage blob download \
  --account-name stterraformstate \
  --container-name tfstate \
  --name landing-zone/global.tfstate \
  --file backup.tfstate

# Upload restored state
az storage blob upload \
  --account-name stterraformstate \
  --container-name tfstate \
  --name landing-zone/global.tfstate \
  --file backup.tfstate
```

## 🔒 Security Best Practices

### Access Control
- **Platform Team**: Full access to landing zone state
- **App Teams**: Access only to their application states
- **CI/CD**: Service principal with appropriate permissions

### State File Protection
- ✅ **Versioning**: Enabled for all state files
- ✅ **Soft Delete**: 30-day retention
- ✅ **Encryption**: At rest and in transit
- ✅ **Access Logging**: All operations logged

### Secrets Management
```bash
# Never store secrets in state files
# Use Azure Key Vault instead
az keyvault secret set --vault-name mykv --name "db-password" --value "secret"
```

## 📊 Monitoring State Files

### Check State File Size
```bash
az storage blob show \
  --account-name stterraformstate \
  --container-name tfstate \
  --name landing-zone/global.tfstate \
  --query properties.contentLength
```

### List All State Files
```bash
az storage blob list \
  --account-name stterraformstate \
  --container-name tfstate \
  --query "[].name"
```

### Backup All State Files
```bash
# Create backup directory
mkdir -p backups/$(date +%Y%m%d)

# Download all state files
az storage blob download-batch \
  --account-name stterraformstate \
  --source tfstate \
  --destination backups/$(date +%Y%m%d)
```

## 🎯 Benefits of This Approach

1. **Isolation**: Landing zone and applications are independent
2. **Scalability**: Multiple applications can be deployed independently
3. **Security**: Different teams have different access levels
4. **Reliability**: State file corruption affects only one concern
5. **Flexibility**: Easy to add new applications or environments
6. **CI/CD**: Each application can have its own deployment pipeline
