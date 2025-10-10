# AutomatedDataFeed Production Environment Configuration
# Apply with: terraform apply -var-file="prod.tfvars"
app_name = "automateddatafeed"
######## Web App Service Configuration ########
app_service_sku       = "P2v3"   # Premium tier for production
app_service_always_on = true     # Always enable for production

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "v8.0"

# Health Check
health_check_path = "/health"

# CORS Configuration
cors_allowed_origins = [
  # Add production-specific origins as needed
]

# Additional App Settings
additional_app_settings = {
  "ENVIRONMENT" = "Production"
}

######## Function App Configuration ########
function_app_sku         = "EP1"  # Premium plan for production
function_app_always_on   = true
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  "name" = "AutomatedDataFeed-Functions"
}

# Network Configuration
enable_private_endpoint = true # Always use private endpoints in production

