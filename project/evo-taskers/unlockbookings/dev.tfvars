# UnlockBookings Dev Environment Configuration
# This file contains environment-specific values for the UnlockBookings application

# Environment identifier (required)
environment = "dev"
app_name = "unlockbookings"
######## Web App Service Configuration ########
# App Service Configuration
app_service_sku       = "P0v3"   # Basic tier for dev, use S1+ for production
app_service_always_on = false    # Set to true for production

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "v8.0"
function_app_sku         = "P0v3"  # Basic plan for dev, EP1 for production
function_app_always_on   = false   # Can enable for Basic plan
functions_worker_runtime = "dotnet"

# Health Check
health_check_path = "/health"

# CORS Configuration (add allowed origins as needed)
cors_allowed_origins = [
  # Example: "https://yourdomain.com"
]

# Additional App Settings
additional_app_settings = {
  # Add application-specific settings here
  # Example:
  # "MyCustomSetting" = "value"
}



additional_function_app_settings = {
  # Add function-specific settings here
  name = "UnlockBookings-Functions"
  
  # Storage Configuration
  # The following settings configure how the Function App uses storage
  # AzureWebJobsStorage is automatically configured by the module using the common storage account
  
  # Storage connection settings (using managed identity when possible)
  #"AzureWebJobsStorage__accountName" =  Set this to use managed identity for storage
  
  # Content share settings (for deployment packages)
  #"WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" - Auto-configured by module
  #"WEBSITE_CONTENTSHARE" - Auto-configured by Azure
  
  # Blob storage settings (if your functions use blob triggers/bindings)
  #"StorageAccountName" = m""odule.common.storage_account_name"" # Reference to common storage account
  #"StorageAccountKey" = "managedidentity" # Use Key Vault reference or managed identity instead
  
  # Example custom storage connection (if you need additional storage accounts)
  # "CustomStorage__serviceUri" = "https://<storage-account>.blob.core.windows.net"
  #"CustomStorage__credential" = "managedidentity"
}

# Network Configuration
enable_private_endpoint = true # Set to true for production to disable public access
