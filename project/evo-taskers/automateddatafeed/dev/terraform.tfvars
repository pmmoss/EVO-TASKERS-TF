# UnlockBookings Dev Environment Configuration
# This file contains environment-specific values for the UnlockBookings application

# Environment identifier (required)
environment = "dev"
app_name = "automateddatafeed"

######## Web App Service Configuration ########
# App Service Configuration
app_service_sku       = "P0v3"   # Basic tier for dev, use S1+ for production
app_service_always_on = false    # Set to true for production

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "v8.0"

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

######## Function App Configuration ########
# Function App Configuration (if you uncomment the function_app.tf module)
function_app_sku         = "P0v3"  # Basic plan for dev, EP1 for production
function_app_always_on   = false   # Can enable for Basic plan
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  # Add function-specific settings here
  name = "AutomatedDataFeed-Functions"
  
}

# Network Configuration
enable_private_endpoint = true # Set to true for production to disable public access
