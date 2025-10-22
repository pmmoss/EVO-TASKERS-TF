# ==============================================================================
# AUTOMATED DATA FEED - PRODUCTION ENVIRONMENT
# ==============================================================================
# Apply with: terraform apply -var-file="prod.tfvars"
# Using Azure Verified Modules (AVM) for secure-by-default configurations

# ==============================================================================
# BASIC CONFIGURATION
# ==============================================================================
environment = "prod"
app_name    = "automateddatafeed"

# ==============================================================================
# FUNCTION APP CONFIGURATION (AVM Web Site Module)
# ==============================================================================
# Function App uses shared Windows Function App Service Plan (EP2)
# No individual SKU needed - uses shared plan

# Runtime Configuration
dotnet_version = "v8.0"

# Additional Function App Settings
additional_function_app_settings = {
  "FUNCTIONS_WORKER_RUNTIME" = "dotnet"
  "FUNCTIONS_EXTENSION_VERSION" = "~4"
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  "ENVIRONMENT" = "Production"
  "DEBUG_MODE" = "false"
  "PERFORMANCE_MODE" = "optimized"
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================
enable_private_endpoint = true # Always use private endpoints in production

# ==============================================================================
# MONITORING & DIAGNOSTICS
# ==============================================================================
# All monitoring is handled by AVM modules with secure defaults
# Application Insights integration is automatic via common infrastructure

