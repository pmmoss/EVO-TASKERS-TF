# EVO-TASKERS Terraform Infrastructure

This repository manages Azure infrastructure for the EVO-TASKERS project using Terraform with separate state files per environment.

## Approach Benefits

- **Single source of truth**: One set of configuration files for all environments
- **DRY principle**: No code duplication across dev/qa/prod
- **Easy maintenance**: Changes apply to all environments from one place
- **Separate state files**: Each environment has its own isolated state file
- **Azure DevOps Integration**: Automated CI/CD pipeline with manual approval gates

## Quick Start

### Initial Setup (Local Development)

```bash
# Navigate to the application directory
cd project/evo-taskers/automateddatafeed

# Initialize Terraform with backend configuration
terraform init \
  -backend-config="resource_group_name=<backend-rg>" \
  -backend-config="storage_account_name=<backend-sa>" \
  -backend-config="container_name=<backend-container>" \
  -backend-config="key=landing-zone/evo-taskers-automateddatafeed-dev.tfstate"
```

### Working with Environments (Local)

Each environment uses a separate state file and tfvars file:

**Development:**
```bash
# Initialize with dev state file
terraform init \
  -backend-config="key=landing-zone/evo-taskers-automateddatafeed-dev.tfstate" \
  -reconfigure

# Plan and apply changes
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

**QA:**
```bash
# Initialize with QA state file
terraform init \
  -backend-config="key=landing-zone/evo-taskers-automateddatafeed-qa.tfstate" \
  -reconfigure

# Plan and apply changes
terraform plan -var-file="qa.tfvars"
terraform apply -var-file="qa.tfvars"
```

**Production:**
```bash
# Initialize with prod state file
terraform init \
  -backend-config="key=landing-zone/evo-taskers-automateddatafeed-prod.tfstate" \
  -reconfigure

# Plan and apply changes
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Azure DevOps Pipeline (Recommended)

The recommended way to deploy infrastructure is through the Azure DevOps pipeline:

1. **Trigger Pipeline**: Run `.azure_pipelines/main-pipeline.yml`
2. **Select Parameters**:
   - Environment: dev/qa/prod
   - Project Name: evo-taskers
   - Application Name: automateddatafeed (or other app)
   - Run Security Scan: true/false (default: true)
   - Run Cost Analysis: true/false (default: true)
   - Fail Pipeline on Security Issues: true/false (default: false)
3. **Plan Stage**: Pipeline runs `terraform plan`
4. **Security Scan** (optional): Scans code for vulnerabilities
5. **Cost Analysis** (optional): Estimates infrastructure costs
6. **Manual Approval**: Review plan, security findings, and costs
7. **Apply Stage**: Pipeline applies approved changes

### Pipeline Features
- ✅ OIDC authentication (secure, no secrets needed)
- ✅ Automated plan/apply workflow
- ✅ Manual approval gate before apply
- ✅ **Security scanning** (Checkov, tfsec, TFLint)
- ✅ **Cost analysis** (Infracost)
- ✅ Artifact preservation
- ✅ Environment-based deployment
- ✅ Reusable templates

### Security & Cost Features

The pipeline includes optional security scanning and cost analysis stages:

**Security Scanning:**
- Scans Terraform code for security vulnerabilities
- Uses industry-standard tools (Checkov, tfsec, TFLint)
- Checks for misconfigurations and compliance issues
- Can be configured to fail pipeline on critical findings

**Cost Analysis:**
- Estimates monthly infrastructure costs before deployment
- Breaks down costs by resource
- Helps identify cost optimization opportunities
- Compares costs across environments

📖 **Setup Guide**: See [`.azure_pipelines/SECURITY-AND-COST-SETUP.md`](.azure_pipelines/SECURITY-AND-COST-SETUP.md) for detailed setup instructions.

## Files Structure

```
automateddatafeed/
├── backend.tf                    # Backend configuration for Azure Storage
├── main.tf                       # Main infrastructure code
├── variables.tf                  # Variable definitions
├── outputs.tf                    # Output definitions
├── app_service.tf               # App Service module (if used)
├── windows_function_app.tf      # Function App module
├── dev.tfvars                   # Dev environment values
├── qa.tfvars                    # QA environment values
├── prod.tfvars                  # Prod environment values
```

## How State Management Works

### Separate State Files

Each environment has its own dedicated state file in Azure Storage:

- **dev**: `landing-zone/evo-taskers-automateddatafeed-dev.tfstate`
- **qa**: `landing-zone/evo-taskers-automateddatafeed-qa.tfstate`
- **prod**: `landing-zone/evo-taskers-automateddatafeed-prod.tfstate`

This approach provides:
- Complete isolation between environments
- No risk of workspace selection errors
- Clear state file naming and organization
- Better traceability in Azure Storage

### Environment Detection

The environment is passed via tfvars files and used in locals:

```hcl
variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

locals {
  environment = var.environment
}
```

This is used throughout the configuration to:
- Name resources appropriately (e.g., `rg-evo-taskers-automateddatafeed-dev`)
- Reference the correct common infrastructure
- Tag resources with the environment
- Configure environment-specific settings

### Environment-Specific Configuration

Each environment has its own `.tfvars` file with environment-specific values:

| Setting | Dev | QA | Prod |
|---------|-----|-----|------|
| App Service SKU | P0v3 | P1v3 | P2v3 |
| Always On | false | true | true |
| Function App SKU | P0v3 | P1v3 | EP1 |
| Private Endpoint | false | true | true |

## Common Operations

### Check What Would Change
```bash
# For dev
terraform init -backend-config="key=landing-zone/evo-taskers-automateddatafeed-dev.tfstate" -reconfigure
terraform plan -var-file="dev.tfvars"

# For prod
terraform init -backend-config="key=landing-zone/evo-taskers-automateddatafeed-prod.tfstate" -reconfigure
terraform plan -var-file="prod.tfvars"
```

### View Current State
```bash
terraform show
```

### View Outputs
```bash
terraform output
```

### List All Resources in State
```bash
terraform state list
```

### Inspect Specific Resource
```bash
terraform state show <resource_address>
# Example: terraform state show azurerm_resource_group.app
```

### Destroy Resources (BE CAREFUL!)
```bash
# Make sure you're pointing to the correct environment state file
terraform init -backend-config="key=landing-zone/evo-taskers-automateddatafeed-dev.tfstate" -reconfigure

# Plan the destroy
terraform plan -destroy -var-file="dev.tfvars"

# Execute the destroy (requires confirmation)
terraform destroy -var-file="dev.tfvars"
```

## Safety Features

### Environment Validation

The configuration includes validation to ensure the environment variable is valid:

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, or prod"
  }
}
```

This ensures you cannot accidentally deploy with an invalid environment value.

### Manual Approval Gate

The Azure DevOps pipeline includes a manual approval stage:
- Plan runs automatically
- Pipeline pauses for manual review
- Approver reviews plan output
- Apply only runs after explicit approval

### State File Isolation

Each environment uses a completely separate state file, preventing:
- Accidental cross-environment changes
- State file corruption affecting multiple environments
- Confusion from workspace selection

## Best Practices

1. **Use the pipeline**: Deploy through Azure DevOps pipeline instead of locally
2. **Always verify state file**: Check your backend config points to the correct environment
3. **Use the correct tfvars**: Always specify `-var-file="<env>.tfvars"` when planning/applying
4. **Review before applying**: Always run `plan` before `apply`
5. **Enable security scanning**: Keep security scans enabled to catch vulnerabilities early
6. **Monitor costs**: Review cost analysis reports to avoid budget surprises
7. **Protect production**: 
   - Use pipeline approvals for prod deployments
   - Enable `failOnSecurityIssues: true` for production
   - Require PR reviews for changes
   - Test in dev/qa first
8. **Never force-unlock lightly**: Only unlock state if you're certain no other process is running

## Troubleshooting

### State Lock Issues
If you encounter a state lock (usually happens when a previous run was interrupted):

```bash
# View the error - it will show the lock ID
terraform plan -var-file="dev.tfvars"

# Force unlock (only if you're CERTAIN no other process is running)
terraform force-unlock <lock-id>
```

**Important**: Only force-unlock if you're absolutely sure no other Terraform process (including pipelines) is running.

### Backend Authentication Issues

If you get authentication errors during `terraform init`:

```bash
# Make sure you're logged into Azure CLI
az login

# Verify your subscription
az account show

# If using a service principal, set environment variables:
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

### Wrong State File

If you realize you initialized with the wrong state file:

```bash
# Re-initialize with the correct state file
terraform init \
  -backend-config="key=landing-zone/evo-taskers-automateddatafeed-<correct-env>.tfstate" \
  -reconfigure
```

## Architecture

This application uses:

- **Windows Function App**: For background processing and scheduled jobs
- **App Service** (optional): For web API (currently commented out)
- **Common Infrastructure**: VNet, Key Vault, Storage, App Insights, etc.

All components are connected via:
- VNet integration for outbound traffic
- Private endpoints for inbound traffic (QA/Prod)
- Managed Identity for authentication
- Application Insights for monitoring
