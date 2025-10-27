# SendGrid Function QA Environment Configuration
# Apply with: terraform apply -var-file="qa.tfvars"

# Environment identifier (required)
environment = "qa"
app_name = "sendgridfunction"
######## Web App Service Configuration ########
app_service_sku       = "P1v3"   # Standard tier for QA
app_service_always_on = true     # Enable for QA

# Runtime Configuration
runtime_stack  = "dotnet"
dotnet_version = "v8.0"

# Health Check
health_check_path = "/health"

# CORS Configuration
cors_allowed_origins = [
  # Add QA-specific origins as needed
]

# Additional App Settings
additional_app_settings = {
  "ENVIRONMENT" = "QA"
}

######## Function App Configuration ########
function_app_sku         = "P1v3"  # Standard plan for QA
function_app_always_on   = true
functions_worker_runtime = "dotnet"

additional_function_app_settings = {
  "name" = "SendGridFunction"
}

# Network Configuration
enable_private_endpoint = true # Private endpoints in QA

