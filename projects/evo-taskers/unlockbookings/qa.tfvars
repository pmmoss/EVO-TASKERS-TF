# UnlockBookings QA Environment Configuration
# This file contains environment-specific values for the UnlockBookings application

# Environment identifier (required)
environment = "qa"
app_name = "unlockbookings"

######## Web App Service Configuration ########
# App Service Configuration
app_service_sku       = "P0v3"   # Basic tier for qa, use S1+ for production
app_service_always_on = true     # Enabled for QA

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Health Check
health_check_path = "/health"

# CORS Configuration (add allowed origins as needed)
cors_allowed_origins = [
  # Add QA-specific origins here
]

# Additional App Settings
additional_app_settings = {
  # Add QA-specific settings here
}

######## Function App Configuration ########
# Function App Configuration
function_app_sku         = "P0v3"  # Basic plan for qa
function_app_always_on   = true    # Enabled for QA
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  name = "UnlockBookings-Functions"
  
  # Storage Configuration (QA)
  # For QA, consider using managed identity for better security
  # See STORAGE-CONFIG.md for detailed storage configuration options
  
  # Option 1: Use managed identity (recommended)
  # "AzureWebJobsStorage__accountName" = "stevotaskersqaeus"
  # "AzureWebJobsStorage__credential"  = "managedidentity"
  
  # Option 2: Use access key (default, auto-configured by module)
  # No additional settings needed - module handles this automatically
  
  # Custom storage connections (if needed)
  # "CustomStorage__serviceUri" = "https://<storage-account>.blob.core.windows.net"
  # "CustomStorage__credential" = "managedidentity"
}

# Network Configuration
enable_private_endpoint = true # Enable for QA

# Logic App Standard Configuration
logic_app_sku = "WS1" # WS1, WS2, WS3 for Workflow Standard
logic_app_storage_share_name = "unlockbookings-workflow-content"
use_extension_bundle = true
bundle_version = "[1.*, 2.0.0)"

# Additional Logic App Settings
additional_logic_app_settings = {
  # Add workflow-specific settings here
  "WorkflowName" = "UnlockBookingsWorkflow"
  
  # Workflow runtime settings
  "Workflows.Connection.AuthenticationAudience" = "https://management.azure.com/"
  
  # Example: Configure connector settings
  # "azureblob-connectionKey" = "@Microsoft.KeyVault(SecretUri=https://your-keyvault.vault.azure.net/secrets/blob-connection-key/)"
}

