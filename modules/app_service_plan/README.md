# App Service Plan Module

This module creates an Azure App Service Plan that can be shared across multiple Function Apps, Web Apps, and Logic Apps.

## Features

- Support for both Linux and Windows OS types
- Flexible SKU configuration (Consumption, Premium, Standard, etc.)
- Zone redundancy for high availability
- Per-site scaling capability
- Optional autoscaling with CPU and memory-based rules
- Custom naming or convention-based naming

## Usage

### Basic Usage - Shared Function App Plan

```hcl
module "shared_function_plan" {
  source = "./modules/app_service_plan"
  
  project            = "evotaskers"
  plan_name          = "functions"
  environment        = "prod"
  location           = "East US"
  location_short     = "eus"
  resource_group_name = "rg-evotaskers-prod-eus"
  
  os_type  = "Windows"
  sku_name = "EP1"  # Elastic Premium for production functions
  
  plan_purpose = "Shared Function Apps"
  
  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Usage - Linux Web App Plan with Autoscaling

```hcl
module "web_app_plan" {
  source = "./modules/app_service_plan"
  
  project            = "evotaskers"
  plan_name          = "webapps"
  environment        = "prod"
  location           = "East US"
  location_short     = "eus"
  resource_group_name = "rg-evotaskers-prod-eus"
  
  os_type  = "Linux"
  sku_name = "P1V3"
  
  # High availability
  zone_redundant = true
  worker_count   = 3
  
  # Autoscaling
  enable_autoscale            = true
  autoscale_min_capacity      = 3
  autoscale_max_capacity      = 10
  autoscale_default_capacity  = 3
  autoscale_cpu_threshold_up  = 70
  autoscale_cpu_threshold_down = 30
  
  plan_purpose = "Production Web Applications"
  
  tags = {
    Environment = "prod"
    CostCenter  = "Engineering"
  }
}
```

### Consumption Plan for Development

```hcl
module "dev_function_plan" {
  source = "./modules/app_service_plan"
  
  project            = "evotaskers"
  plan_name          = "functions-dev"
  environment        = "dev"
  location           = "East US"
  location_short     = "eus"
  resource_group_name = "rg-evotaskers-dev-eus"
  
  os_type  = "Windows"
  sku_name = "Y1"  # Consumption plan
  
  plan_purpose = "Development Functions"
  
  tags = {
    Environment = "dev"
  }
}
```

## Common SKU Options

### Function Apps
- **Y1**: Consumption (pay-per-execution)
- **EP1, EP2, EP3**: Elastic Premium (pre-warmed instances, VNet integration)
- **P1V2, P2V2, P3V2**: Premium V2
- **P1V3, P2V3, P3V3**: Premium V3 (best performance)

### Web Apps
- **B1, B2, B3**: Basic (dev/test workloads)
- **S1, S2, S3**: Standard (production workloads)
- **P1V2, P2V2, P3V2**: Premium V2 (high-scale production)
- **P1V3, P2V3, P3V3**: Premium V3 (latest generation)

### Logic Apps
- **WS1, WS2, WS3**: Workflow Standard (Logic Apps Standard)

## Sharing an App Service Plan

Once created, reference the plan ID in your app modules:

```hcl
module "shared_plan" {
  source = "./modules/app_service_plan"
  # ... configuration
}

module "function_app_1" {
  source = "./modules/windows_function_app"
  
  create_service_plan     = false
  existing_service_plan_id = module.shared_plan.id
  
  # ... other configuration
}

module "function_app_2" {
  source = "./modules/windows_function_app"
  
  create_service_plan     = false
  existing_service_plan_id = module.shared_plan.id
  
  # ... other configuration
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | n/a | yes |
| plan_name | Name suffix for the App Service Plan | `string` | n/a | yes |
| environment | Environment (dev, qa, prod) | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| location_short | Short name for Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| os_type | Operating system type (Linux or Windows) | `string` | n/a | yes |
| sku_name | SKU name for the App Service Plan | `string` | n/a | yes |
| custom_name | Custom name (overrides naming convention) | `string` | `null` | no |
| plan_purpose | Purpose description for tagging | `string` | `"App Hosting"` | no |
| zone_redundant | Enable zone redundancy | `bool` | `false` | no |
| per_site_scaling_enabled | Enable per-site scaling | `bool` | `false` | no |
| worker_count | Number of workers | `number` | `1` | no |
| enable_autoscale | Enable autoscaling | `bool` | `false` | no |
| autoscale_min_capacity | Minimum instance count | `number` | `1` | no |
| autoscale_max_capacity | Maximum instance count | `number` | `3` | no |
| autoscale_cpu_threshold_up | CPU % to scale up | `number` | `70` | no |
| autoscale_cpu_threshold_down | CPU % to scale down | `number` | `30` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the App Service Plan |
| name | The name of the App Service Plan |
| os_type | The OS type of the App Service Plan |
| sku_name | The SKU name of the App Service Plan |
| location | The Azure region |
| resource_group_name | The resource group name |
| zone_balancing_enabled | Whether zone balancing is enabled |
| worker_count | The number of workers |

## Notes

- Consumption plans (Y1) don't support always-on or VNet integration
- Zone redundancy requires Premium V2/V3 or Elastic Premium SKUs
- Autoscaling is only available for Standard and Premium tiers
- Per-site scaling allows apps to scale independently on shared plans

