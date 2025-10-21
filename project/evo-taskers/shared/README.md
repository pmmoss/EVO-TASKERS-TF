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

1. **Windows Function App Service Plan** (`windows_function_plan`)
   - Shared by all Windows Function Apps
   - SKU: EP1 (dev), EP2 (prod)
   - Autoscaling enabled in prod

2. **Logic App Service Plan** (`logic_app_plan`)
   - Used by Logic App Standard instances
   - SKU: WS1 (dev/qa), WS2 (prod)

### Windows Function Apps

All Windows Function Apps are now deployed in this shared module:

1. **automateddatafeed** - Automated data feed processing
2. **autoopenshorex** - Auto open shore operations
3. **dashboard** - Dashboard backend services
4. **sendgridfunction** - SendGrid email integration
5. **unlockbookings** - Bookings function app

Each function app:
- Uses the shared Windows Function App Service Plan
- Has VNet integration for outbound traffic
- Can have private endpoints for inbound traffic (configurable)
- Uses shared monitoring (App Insights, Log Analytics)
- Uses shared managed identity from common module

### Logic Apps

1. **unlockbookings-workflow** - Booking management workflows
   - Uses shared Logic App Service Plan
   - Configured with extension bundles
   - VNet integrated with private endpoint support

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

Applications reference the shared state to access deployed function apps and logic apps:

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

# Reference deployed function app from shared module
output "function_app_name" {
  value = data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_name
}

output "function_app_hostname" {
  value = data.terraform_remote_state.shared.outputs.automateddatafeed_function_app_default_hostname
}
```

**Note**: Function apps and logic apps are NO LONGER created in individual application modules. They are created here in the shared module and referenced via remote state.

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

### Service Plan Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| environment | Environment (dev, qa, prod) | string | - |
| windows_function_plan_sku | SKU for Windows functions | string | "EP1" |
| windows_function_plan_enable_autoscale | Enable autoscaling | bool | false |
| windows_function_plan_min_capacity | Min instances for autoscale | number | 1 |
| windows_function_plan_max_capacity | Max instances for autoscale | number | 5 |
| logic_app_plan_sku | SKU for Logic Apps | string | "WS1" |

### Application Configuration

| Name | Description | Type |
|------|-------------|------|
| automateddatafeed_enable_private_endpoint | Enable private endpoint | bool |
| automateddatafeed_additional_settings | Additional app settings | map(string) |
| autoopenshorex_enable_private_endpoint | Enable private endpoint | bool |
| autoopenshorex_additional_settings | Additional app settings | map(string) |
| dashboard_enable_private_endpoint | Enable private endpoint | bool |
| dashboard_additional_settings | Additional app settings | map(string) |
| sendgridfunction_enable_private_endpoint | Enable private endpoint | bool |
| sendgridfunction_additional_settings | Additional app settings | map(string) |
| unlockbookings_enable_private_endpoint | Enable private endpoint | bool |
| unlockbookings_additional_logic_settings | Logic app settings | map(string) |
| unlockbookings_additional_function_settings | Function app settings | map(string) |

### Runtime Configuration

| Name | Description | Type | Default |
|------|-------------|------|---------|
| functions_worker_runtime | Functions runtime | string | "dotnet" |
| dotnet_version | .NET version | string | "v8.0" |

## Outputs

### Service Plans

| Name | Description |
|------|-------------|
| windows_function_plan_id | ID of shared Windows function plan |
| windows_function_plan_name | Name of shared Windows function plan |
| windows_function_plan_sku | SKU of shared Windows function plan |
| logic_app_plan_id | ID of shared Logic App plan |
| logic_app_plan_name | Name of shared Logic App plan |
| logic_app_plan_sku | SKU of shared Logic App plan |

### Function Apps

For each app (automateddatafeed, autoopenshorex, dashboard, sendgridfunction, unlockbookings):

| Name | Description |
|------|-------------|
| {app}_function_app_id | Function App ID |
| {app}_function_app_name | Function App name |
| {app}_function_app_default_hostname | Function App hostname |
| {app}_function_app_identity_principal_id | Managed identity principal ID |

### Logic Apps

| Name | Description |
|------|-------------|
| unlockbookings_logic_app_id | Logic App ID |
| unlockbookings_logic_app_name | Logic App name |
| unlockbookings_logic_app_default_hostname | Logic App hostname |
| unlockbookings_logic_app_identity_principal_id | Managed identity principal ID |

## Support

For questions or issues, refer to:
- [MIGRATION-GUIDE.md](../../../modules/MIGRATION-GUIDE.md)
- [QUICK-REFERENCE.md](../../../modules/QUICK-REFERENCE.md)

