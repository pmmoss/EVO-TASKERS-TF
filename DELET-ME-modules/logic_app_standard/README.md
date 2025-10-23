# Logic App Standard Module

This module creates an Azure Logic App Standard (Workflow Standard) with all necessary resources including:
- App Service Plan (Workflow Standard SKU)
- Logic App Standard instance
- VNet integration for outbound traffic
- Optional private endpoint for inbound traffic
- Managed identity integration
- Application Insights monitoring
- Diagnostic settings

## Features

- **Workflow Standard Plan**: Deploys Logic App with WS1, WS2, or WS3 SKU
- **Managed Identity**: Uses user-assigned managed identity for secure access to Azure resources
- **VNet Integration**: Connects to virtual network for secure outbound traffic
- **Private Endpoint**: Optional private endpoint for secure inbound access
- **Storage Account**: Uses shared storage account from common infrastructure
- **Monitoring**: Integrates with Application Insights and Log Analytics
- **Key Vault Integration**: References secrets from Key Vault using managed identity
- **Extension Bundle**: Supports workflow extension bundles for built-in connectors

## Usage

```hcl
module "logic_app_standard" {
  source = "../../../modules/logic_app_standard"
  
  # Application identifier
  app_name = "myworkflow"
  
  # Project configuration
  project        = "evotaskers"
  environment    = "dev"
  location       = "eastus"
  location_short = "eus"
  
  # Resource group
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  # SKU configuration
  sku_name = "WS1"  # WS1, WS2, or WS3
  
  # Storage account (required for Logic App Standard)
  storage_account_name       = data.terraform_remote_state.common.outputs.storage_account_name
  storage_account_access_key = data.terraform_remote_state.common.outputs.storage_account_primary_access_key
  storage_account_share_name = "myworkflow-content"
  
  # Managed Identity
  user_assigned_identity_id        = data.terraform_remote_state.common.outputs.workload_identity_id
  user_assigned_identity_client_id = data.terraform_remote_state.common.outputs.workload_identity_client_id
  
  # Networking
  enable_vnet_integration = true
  subnet_id              = data.terraform_remote_state.common.outputs.app_integration_subnet_id
  
  # Private endpoint (optional)
  enable_private_endpoint    = true
  private_endpoint_subnet_id = data.terraform_remote_state.common.outputs.private_endpoints_subnet_id
  
  # Monitoring
  app_insights_connection_string   = data.terraform_remote_state.common.outputs.app_insights_connection_string
  app_insights_instrumentation_key = data.terraform_remote_state.common.outputs.app_insights_instrumentation_key
  log_analytics_workspace_id       = data.terraform_remote_state.common.outputs.log_analytics_workspace_id
  enable_diagnostics              = true
  
  # Key Vault
  key_vault_uri = data.terraform_remote_state.common.outputs.key_vault_uri
  
  # Extension bundle
  use_extension_bundle = true
  bundle_version      = "[1.*, 2.0.0)"
  
  # Additional app settings
  additional_app_settings = {
    "WorkflowName" = "MyWorkflow"
  }
  
  tags = {
    Application = "MyApp"
    Environment = "dev"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| azurerm_service_plan.this | resource |
| azurerm_logic_app_standard.this | resource |
| azurerm_private_endpoint.logic_app | resource |
| azurerm_monitor_diagnostic_setting.logic_app | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project name | `string` | n/a | yes |
| app_name | Application name | `string` | n/a | yes |
| environment | Environment (dev, qa, prod) | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| location_short | Short name for Azure region | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| sku_name | SKU for App Service Plan (WS1, WS2, WS3) | `string` | `"WS1"` | no |
| storage_account_name | Storage account name | `string` | n/a | yes |
| storage_account_access_key | Storage account access key | `string` | n/a | yes |
| storage_account_share_name | Storage file share name | `string` | `"logic-app-content"` | no |
| user_assigned_identity_id | User-assigned managed identity ID | `string` | n/a | yes |
| user_assigned_identity_client_id | User-assigned managed identity client ID | `string` | n/a | yes |
| app_insights_connection_string | Application Insights connection string | `string` | n/a | yes |
| app_insights_instrumentation_key | Application Insights instrumentation key | `string` | n/a | yes |
| key_vault_uri | Key Vault URI | `string` | n/a | yes |
| enable_vnet_integration | Enable VNet integration | `bool` | `true` | no |
| subnet_id | Subnet ID for VNet integration | `string` | `null` | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for private endpoint | `string` | `null` | no |
| enable_diagnostics | Enable diagnostic settings | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| use_extension_bundle | Enable extension bundle | `bool` | `true` | no |
| bundle_version | Extension bundle version range | `string` | `"[1.*, 2.0.0)"` | no |
| additional_app_settings | Additional app settings | `map(string)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| logic_app_id | The ID of the Logic App |
| logic_app_name | The name of the Logic App |
| logic_app_default_hostname | The default hostname of the Logic App |
| logic_app_identity_principal_id | The principal ID of the managed identity |
| service_plan_id | The ID of the App Service Plan |
| service_plan_name | The name of the App Service Plan |
| private_endpoint_id | The ID of the private endpoint |
| private_endpoint_private_ip | The private IP of the private endpoint |

## Notes

### Storage Account
Logic App Standard requires a storage account for storing workflow state and runtime data. The storage account should be created in the common infrastructure and referenced here.

### VNet Integration
VNet integration is enabled by default and allows the Logic App to access resources in your virtual network through outbound connections.

### Private Endpoint
When enabled, the private endpoint provides secure inbound access to the Logic App through a private IP address in your VNet.

### Extension Bundle
The extension bundle provides built-in connectors and actions for Logic Apps. The default version range `[1.*, 2.0.0)` ensures compatibility with most workflows.

### Workflow Development
After deploying the Logic App, you can develop workflows using:
- Azure Portal (Logic App Designer)
- Visual Studio Code with Azure Logic Apps extension
- Infrastructure as Code (deploying workflow definitions)

### Key Vault Integration
Secrets can be referenced from Key Vault using the `@Microsoft.KeyVault()` syntax in app settings:
```
"MySecret" = "@Microsoft.KeyVault(SecretUri=https://your-vault.vault.azure.net/secrets/my-secret/)"
```

The managed identity must have appropriate access policies in Key Vault.

## Example Workflow Configuration

Add these settings to `additional_app_settings` for workflow-specific configuration:

```hcl
additional_app_settings = {
  "WorkflowName" = "UnlockBookingsWorkflow"
  "Workflows.Connection.AuthenticationAudience" = "https://management.azure.com/"
  
  # Connector settings (using Key Vault references)
  "azureblob-connectionKey" = "@Microsoft.KeyVault(SecretUri=https://vault.vault.azure.net/secrets/blob-key/)"
}
```

