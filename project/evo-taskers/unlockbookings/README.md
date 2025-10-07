# UnlockBookings Application Infrastructure

This directory contains Terraform configurations for deploying the UnlockBookings application across multiple environments (dev, qa, prod).

## 🏗️ Architecture

The UnlockBookings application uses a **two-tier deployment model**:

### Tier 1: Common Infrastructure (Shared)
Located in `../common/{environment}/`
- Virtual Network & Subnets
- User-Assigned Managed Identity
- Key Vault
- Application Insights
- Log Analytics
- Storage Account
- Bastion (optional)

### Tier 2: Application Infrastructure (This)
Located in `./{environment}/`
- App Service (Linux)
- Function App (optional)
- Private Endpoints (optional)
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
│  • Storage                             │
└──────────────┬──────────────────────────┘
               │
               │ Remote State Reference
               │
┌──────────────▼──────────────────────────┐
│     UnlockBookings Application          │
│  (Can be deployed independently)        │
│                                         │
│  • App Service (Linux .NET 8.0)        │
│  • Function App (optional)             │
│  • Secure by default                   │
└─────────────────────────────────────────┘
```

## 🔒 Security Features

### Secure by Default

✅ **HTTPS Only** - All traffic enforced over HTTPS  
✅ **TLS 1.2 Minimum** - Modern encryption standards  
✅ **FTP Disabled** - No legacy FTP access  
✅ **Managed Identity** - No credentials in code  
✅ **VNet Integration** - Outbound traffic through private network  
✅ **Key Vault Integration** - All secrets stored securely  
✅ **Application Insights** - Full monitoring and diagnostics  
✅ **Diagnostic Logging** - All logs sent to Log Analytics  

### Optional (Recommended for Production)

🔐 **Private Endpoints** - Block public access entirely  
🔐 **Custom Domain** - with managed SSL certificates  
🔐 **Auto-scaling** - Handle traffic spikes  
🔐 **Deployment Slots** - Zero-downtime deployments  

## 📁 Directory Structure

```
unlockbookings/
├── README.md                    # This file
├── DEPLOYMENT-GUIDE.md          # Step-by-step deployment guide
│
├── dev/                         # Development environment
│   ├── README.md               # Dev-specific documentation
│   ├── backend.tf              # Remote state configuration
│   ├── main.tf                 # Remote state data source & locals
│   ├── app_service.tf          # App Service configuration
│   ├── function_app.tf         # Function App (optional, commented out)
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   └── terraform.tfvars        # Environment-specific values
│
├── qa/                          # QA environment (future)
│   └── ...
│
└── prod/                        # Production environment (future)
    └── ...
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** v1.5+ installed
3. **Common infrastructure** deployed (in `../common/dev/`)

### Deploy

```bash
# 1. Navigate to environment directory
cd dev

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Deploy
terraform apply

# 5. Get the app URL
terraform output app_service_url
```

**See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for detailed instructions.**

## 🔧 Configuration

### Basic App Service

Edit `dev/terraform.tfvars`:

```hcl
# App Service tier
app_service_sku       = "B1"     # B1, S1, P1V2, etc.
app_service_always_on = false    # true for production

# Runtime
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Network security
enable_private_endpoint = false  # true for production
```

### Adding Application Settings

```hcl
additional_app_settings = {
  "MyFeatureFlag" = "true"
  
  # Reference Key Vault secrets
  "ConnectionString" = "@Microsoft.KeyVault(SecretUri=https://kv.vault.azure.net/secrets/db/)"
}
```

### Enable Function App

Uncomment the module in `dev/function_app.tf` and run `terraform apply`.

## 📊 Monitoring

### Application Insights

Automatically configured for:
- Request/Response tracking
- Dependency tracking
- Exception logging
- Performance metrics
- Custom telemetry

Access at: Azure Portal → Application Insights → Your App Insights instance

### Diagnostic Logs

All logs sent to Log Analytics:
- HTTP access logs
- Console output
- Application logs
- Audit logs

View at: App Service → Monitoring → Log Stream

## 🚢 Azure DevOps Deployment

### Pipeline Setup

1. Create service connection in Azure DevOps
2. Create `azure-pipelines.yml` in your app repo
3. Configure pipeline to deploy to the App Service

**See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md#azure-devops-deployment) for complete pipeline configuration.**

### Example Pipeline

```yaml
- task: AzureWebApp@1
  inputs:
    azureSubscription: 'Your-Service-Connection'
    appType: 'webAppLinux'
    appName: '$(appServiceName)'  # From terraform output
    package: '$(Build.ArtifactStagingDirectory)/**/*.zip'
    runtimeStack: 'DOTNETCORE|8.0'
```

## 🔑 Managed Identity Usage

### In Terraform

The user-assigned identity is automatically configured from the common infrastructure:

```hcl
user_assigned_identity_id        = data.terraform_remote_state.common.outputs.workload_identity_id
user_assigned_identity_client_id = data.terraform_remote_state.common.outputs.workload_identity_client_id
```

### In Application Code

```csharp
using Azure.Identity;

// Automatically uses the assigned managed identity
var credential = new DefaultAzureCredential();

// Access Key Vault
var client = new SecretClient(new Uri(keyVaultUri), credential);
var secret = await client.GetSecretAsync("my-secret");
```

## 📦 Modules Used

This configuration uses the following modules:

### App Service Module
- Location: `/modules/app_service/`
- Purpose: Secure Linux App Service with managed identity
- [Module README](../../../modules/app_service/README.md)

### Function App Module
- Location: `/modules/function_app/`
- Purpose: Secure Linux Function App with managed identity
- [Module README](../../../modules/function_app/README.md)

### Naming Module
- Location: `/modules/naming/`
- Purpose: Consistent Azure resource naming
- Used automatically by app_service and function_app modules

## 🌍 Environments

### Development (dev/)

- **Purpose**: Development and testing
- **SKU**: B1 (Basic)
- **Always On**: Disabled (cost savings)
- **Private Endpoint**: Disabled (public access for testing)
- **Scaling**: Manual

### QA (qa/)

- **Purpose**: Quality assurance and staging
- **SKU**: S1 (Standard)
- **Always On**: Enabled
- **Private Endpoint**: Optional
- **Scaling**: Manual or auto-scale

### Production (prod/)

- **Purpose**: Live production workloads
- **SKU**: P1V2+ (Premium v2/v3)
- **Always On**: Enabled
- **Private Endpoint**: Enabled (recommended)
- **Scaling**: Auto-scale configured
- **Deployment Slots**: Enabled for blue/green deployments

## 🛠️ Troubleshooting

### App Won't Start

```bash
# View live logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# Check Application Insights for errors
# Azure Portal → App Insights → Failures
```

### Can't Access Key Vault

```bash
# Verify managed identity has access
cd ../common/dev
terraform output workload_identity_principal_id

# Check RBAC assignments in Azure Portal
```

### Deployment Issues

1. Verify service principal has Contributor role
2. Check App Service state in Azure Portal
3. Verify .zip package is valid
4. Review Activity Log for detailed errors

## 📚 Documentation

- **[DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)** - Complete deployment walkthrough
- **[dev/README.md](./dev/README.md)** - Development environment details
- **[../common/dev/README.md](../common/dev/README.md)** - Common infrastructure docs

## 🧹 Clean Up

### Remove App Only

```bash
cd dev
terraform destroy
```

This keeps the common infrastructure (VNet, Key Vault, etc.) for other apps.

### Remove Everything

```bash
# First remove the app
cd dev
terraform destroy

# Then remove common infrastructure
cd ../../common/dev
terraform destroy
```

## 🎯 Best Practices

### Development
- Use Basic (B1) tier for cost savings
- Keep public access enabled for easy testing
- Use Application Insights for debugging
- Test with production-like data structures

### Production
- Use Premium (P1V2+) or higher for SLA
- Enable private endpoints (disable public access)
- Configure auto-scaling
- Use deployment slots
- Enable backups
- Set up alerts
- Use custom domains with managed certificates

### Security
- Never commit secrets to Git
- Always use Key Vault for sensitive data
- Reference secrets via Key Vault references in app settings
- Use managed identity for all Azure service authentication
- Keep runtime versions up to date
- Review diagnostic logs regularly

## 🤝 Contributing

When adding new features:

1. Update module version constraints if needed
2. Add new variables to `variables.tf`
3. Update `terraform.tfvars.example` if applicable
4. Document in README
5. Test in dev before promoting to qa/prod

## 📞 Support

For issues or questions:

1. Check Application Insights → Failures
2. Review Azure Portal → Activity Log
3. Check Terraform state: `terraform show`
4. Review module documentation in `/modules`

## 🔗 Related Resources

- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Functions Documentation](https://learn.microsoft.com/en-us/azure/azure-functions/)
- [Managed Identities](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)

---

**Version**: 1.0  
**Last Updated**: October 2025  
**Maintained By**: Platform Team

