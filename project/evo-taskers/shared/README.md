# EVO-TASKERS Shared Services

This module contains shared infrastructure services used across multiple EVO-TASKERS applications.

## Purpose

The `shared` module sits between the `common` (landing zone) and individual application modules:

```
common/     → Landing zone resources (RG, VNet, KeyVault, Storage, Identity, etc.)
  ↓
shared/     → Shared services (App Service Plans, Event Hubs, APIM, etc.)
  ↓
apps/       → Individual applications (dashboard, unlockbookings, etc.)
```

## What's Included

### App Service Plans

1. **Windows Function App Service Plan** - Shared by:
   - `dashboard`
   - `sendgrid`
   - `automateddatafeed`
   - `autoopenshorex`

2. **Logic App Service Plan** - Shared by:
   - `unlockbookings`

### Future Services (Planned)

- Event Hubs
- API Management (APIM)
- Shared Application Gateway
- Shared Service Bus

## Usage

### Deploy Shared Services

```bash
# Initialize Terraform
cd project/evo-taskers/shared
terraform init

# Plan changes for dev
terraform plan -var-file="dev.tfvars"

# Apply changes
terraform apply -var-file="dev.tfvars"
```

### Reference in Applications

Applications reference the shared state to use shared resources:

```hcl
# In application's main.tf
data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "shared/evo-taskers-shared-${var.environment}.tfstate"
  }
}

# Use shared App Service Plan
module "my_function" {
  source = "../../../modules/windows_function_app"
  
  create_service_plan      = false
  existing_service_plan_id = data.terraform_remote_state.shared.outputs.windows_function_plan_id
  
  # ... rest of config
}
```

## State File Structure

```
tfstate/
├── landing-zone/
│   └── evo-taskers-common-{env}.tfstate    # Common/landing zone
├── shared/
│   └── evo-taskers-shared-{env}.tfstate    # Shared services (this module)
└── apps/
    ├── unlockbookings-{env}.tfstate
    ├── automateddatafeed-{env}.tfstate
    └── ...
```

## Dependencies

- **Depends on:** `common` module (landing zone resources)
- **Used by:** All application modules

## Deployment Order

1. Deploy `common` first (landing zone)
2. Deploy `shared` second (this module)
3. Deploy individual applications

## Cost Optimization

By sharing App Service Plans:
- **Before:** Each app had its own plan → 4 × EP1 = $600/month
- **After:** One shared EP1 plan → $150/month
- **Savings:** $450/month (75% reduction)

## Configuration

### Dev Environment
- Windows Functions: EP1 (no autoscale)
- Logic Apps: WS1

### Production Environment
- Windows Functions: EP2 with autoscaling (1-10 instances)
- Logic Apps: WS1 or WS2 (depending on load)

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| subscription_id | Azure subscription ID | string | - |
| environment | Environment (dev, qa, prod) | string | - |
| windows_function_plan_sku | SKU for Windows functions | string | "EP1" |
| windows_function_plan_enable_autoscale | Enable autoscaling | bool | false |
| logic_app_plan_sku | SKU for Logic Apps | string | "WS1" |

## Outputs

| Name | Description |
|------|-------------|
| windows_function_plan_id | ID of shared Windows function plan |
| windows_function_plan_name | Name of shared Windows function plan |
| logic_app_plan_id | ID of shared Logic App plan |
| logic_app_plan_name | Name of shared Logic App plan |

## Support

For questions or issues, refer to:
- [MIGRATION-GUIDE.md](../../../modules/MIGRATION-GUIDE.md)
- [QUICK-REFERENCE.md](../../../modules/QUICK-REFERENCE.md)

