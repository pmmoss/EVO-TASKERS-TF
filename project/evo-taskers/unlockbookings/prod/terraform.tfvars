# UnlockBookings Production Environment Configuration
# This file contains environment-specific values for the UnlockBookings application

# Environment identifier (required)
environment = "prod"

######## Web App Service Configuration ########
# App Service Configuration
app_service_sku       = "P1v3"   # Premium tier for production
app_service_always_on = true     # Always enabled for production

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "8.0"

# Health Check
health_check_path = "/health"

# CORS Configuration (add allowed origins as needed)
cors_allowed_origins = [
  # Add production-specific origins here
]

# Additional App Settings
additional_app_settings = {
  # Add production-specific settings here
}

######## Function App Configuration ########
# Function App Configuration
function_app_sku         = "EP1"  # Premium plan for production
function_app_always_on   = true   # Always enabled for production
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  name = "UnlockBookings-Functions"
  
  # Storage Configuration (Production)
  # IMPORTANT: Production should use managed identity for security
  # See STORAGE-CONFIG.md for detailed storage configuration options
  
  # Use managed identity (RECOMMENDED for production)
  # Uncomment when ready to migrate from access keys
  # "AzureWebJobsStorage__accountName" = "stevotaskersprodeus"
  # "AzureWebJobsStorage__credential"  = "managedidentity"
  
  # Custom storage connections (if needed)
  # Always use managed identity for production storage
  # "CustomStorage__serviceUri" = "https://<storage-account>.blob.core.windows.net"
  # "CustomStorage__credential" = "managedidentity"
  
  # NEVER use connection strings or access keys directly in production
  # Use Key Vault references if managed identity is not possible:
  # "CustomStorage" = "@Microsoft.KeyVault(SecretUri=https://...)"
}

# Network Configuration
enable_private_endpoint = true # Always enable for production

