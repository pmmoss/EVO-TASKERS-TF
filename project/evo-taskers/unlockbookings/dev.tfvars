# UnlockBookings Dev Environment Configuration
# This file contains environment-specific values for the UnlockBookings application

# ==============================================================================
# BASIC CONFIGURATION
# ==============================================================================

# Environment identifier (required)
environment = "dev"
app_name    = "unlockbookings"

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

# Private endpoint for inbound traffic (recommended for production)
enable_private_endpoint = false  # Set to true for production

# ==============================================================================
# LOGIC APP STANDARD CONFIGURATION
# ==============================================================================

# NOTE: The Logic App uses the shared App Service Plan from the 'shared' module.
# The plan SKU (WS1) is configured in shared/dev.tfvars, not here.

# Storage share name for Logic App content (must be unique per Logic App)
logic_app_storage_share_name = "unlockbookings-workflow-content"

# Extension bundle configuration (enables built-in connectors)
use_extension_bundle = true
bundle_version       = "[1.*, 2.0.0)"

# ==============================================================================
# LOGIC APP SETTINGS
# ==============================================================================

# Additional Logic App application settings
additional_logic_app_settings = {
  # Workflow identification
  "WorkflowName" = "UnlockBookingsWorkflow"
  "WorkflowType" = "Booking Management"
  
  # Workflow runtime settings
  "Workflows.Connection.AuthenticationAudience" = "https://management.azure.com/"
  
  # Example: Configure API connector settings (use Key Vault for secrets)
  # "azureblob-connectionKey" = "@Microsoft.KeyVault(SecretUri=https://your-keyvault.vault.azure.net/secrets/blob-connection-key/)"
  
  # Example: Custom workflow settings
  # "BookingTimeout" = "300"
  # "MaxRetries" = "3"
}

# ==============================================================================
# UNUSED VARIABLES (kept for reference, remove if not needed)
# ==============================================================================

# The following variables are defined in variables.tf but not used by unlockbookings
# since it only deploys a Logic App (not Web App or Function App):

# Web App variables (not used):
# - app_service_sku
# - app_service_always_on  
# - runtime_stack
# - dotnet_version
# - health_check_path
# - cors_allowed_origins
# - additional_app_settings

# Function App variables (not used):
# - function_app_sku (plan SKU now in shared module)
# - function_app_always_on
# - functions_worker_runtime
# - additional_function_app_settings

# Logic App Plan variable (not used):
# - logic_app_sku (plan SKU now defined in shared/dev.tfvars)
