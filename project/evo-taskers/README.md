# sendgris Infrastructure - Workspace-based

This directory contains the Terraform configuration for the AutomatedDataFeed application using **Terraform Workspaces** for environment management.

## Workspace Approach Benefits

- **Single source of truth**: One set of configuration files for all environments
- **DRY principle**: No code duplication across dev/qa/prod
- **Easy maintenance**: Changes apply to all environments from one place
- **Built-in environment switching**: Use `terraform workspace` commands

## Quick Start

### Initial Setup

```bash
# Initialize Terraform
terraform init

# Create workspaces (if they don't exist)
terraform workspace new dev
terraform workspace new qa
terraform workspace new prod

# List all workspaces
terraform workspace list
```

### Working with Environments

```bash
# Select the environment you want to work with
terraform workspace select dev

# Verify you're in the correct workspace
terraform workspace show

# Plan changes for the selected environment
terraform plan -var-file="dev.tfvars"

# Apply changes
terraform apply -var-file="dev.tfvars"
```

### Quick Commands by Environment

**Development:**
```bash
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

**QA:**
```bash
terraform workspace select qa
terraform plan -var-file="qa.tfvars"
terraform apply -var-file="qa.tfvars"
```

**Production:**
```bash
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

## Files Structure

```
automateddatafeed-workspace/
├── backend.tf                    # Backend configuration (workspace-aware)
├── main.tf                       # Main infrastructure code
├── variables.tf                  # Variable definitions
├── outputs.tf                    # Output definitions
├── app_service.tf               # App Service module
├── windows_function_app.tf      # Function App module
├── dev.tfvars                   # Dev environment values
├── qa.tfvars                    # QA environment values
├── prod.tfvars                  # Prod environment values
└── README.md                    # This file
```

## How Workspaces Work

### State Management

Terraform automatically manages separate state files for each workspace:

- **dev workspace**: `evo-taskers-automateddatafeed.tfstateenv:dev`
- **qa workspace**: `evo-taskers-automateddatafeed.tfstateenv:qa`
- **prod workspace**: `evo-taskers-automateddatafeed.tfstateenv:prod`

### Environment Detection

The current workspace name is automatically used as the environment:

```hcl
locals {
  environment = terraform.workspace  # Returns "dev", "qa", or "prod"
}
```

This is used throughout the configuration to:
- Name resources appropriately
- Reference the correct common infrastructure
- Tag resources with the environment

### Environment-Specific Configuration

Each environment has its own `.tfvars` file with environment-specific values:

| Setting | Dev | QA | Prod |
|---------|-----|-----|------|
| App Service SKU | P0v3 | P1v3 | P2v3 |
| Always On | false | true | true |
| Function App SKU | P0v3 | P1v3 | EP1 |
| Private Endpoint | false | true | true |

## Common Operations

### View Current Workspace
```bash
terraform workspace show
```

### List All Workspaces
```bash
terraform workspace list
```

### Check What Would Change
```bash
# For dev
terraform workspace select dev
terraform plan -var-file="dev.tfvars"

# For prod
terraform workspace select prod
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

### Destroy Resources (BE CAREFUL!)
```bash
# Select the workspace first
terraform workspace select dev

# Plan the destroy
terraform plan -destroy -var-file="dev.tfvars"

# Execute the destroy
terraform destroy -var-file="dev.tfvars"
```

## Safety Features

### Workspace Validation

The configuration includes validation to prevent accidental use of the wrong workspace:

```hcl
resource "null_resource" "workspace_validation" {
  lifecycle {
    precondition {
      condition     = contains(["dev", "qa", "prod"], terraform.workspace)
      error_message = "Workspace must be one of: dev, qa, prod"
    }
  }
}
```

This ensures you cannot accidentally apply changes while in an invalid workspace.

## Best Practices

1. **Always verify workspace**: Run `terraform workspace show` before applying changes
2. **Use the correct tfvars**: Always specify `-var-file="<env>.tfvars"` when planning/applying
3. **Never use 'default' workspace**: Create and use named workspaces (dev/qa/prod)
4. **Review before applying**: Always run `plan` before `apply`
5. **Protect production**: Use branch protection and approvals for prod changes


### State Lock Issues
If you encounter a state lock:
```bash
# View lock info
terraform force-unlock <lock-id>

# Only use this if you're certain no other process is running
```

### Need to See All Resources
```bash
terraform state list
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
