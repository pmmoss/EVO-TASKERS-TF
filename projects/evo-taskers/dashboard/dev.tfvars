# Dashboard Dev Environment Configuration
# Apply with: terraform apply -var-file="dev.tfvars"

# Environment identifier (required)
environment = "dev"
app_name = "dashboard"
######## Web App Service Configuration ########
app_service_sku       = "P0v3"   # Basic tier for dev
app_service_always_on = false    # Can be false for dev to save costs

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "v8.0"

# Health Check
health_check_path = "/health"

# CORS Configuration
cors_allowed_origins = [
  # Add dev-specific origins as needed
]

# Additional App Settings
additional_app_settings = {
  "ENVIRONMENT" = "Development"
}

######## Function App Configuration ########
function_app_sku         = "P0v3"  # Basic plan for dev
function_app_always_on   = false
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  "name" = "Dashboard-Functions"
}

# Network Configuration
enable_private_endpoint = false # Public access OK for dev

