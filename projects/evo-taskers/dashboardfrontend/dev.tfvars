# Dashboard Frontend - Development Environment Configuration
# Apply with: terraform apply -var-file="dev.tfvars"

# ==============================================================================
# APPLICATION IDENTIFIER
# ==============================================================================

# Environment identifier (required)
environment = "dev"
app_name = "dashboardfrontend"

# ==============================================================================
# APP SERVICE PLAN CONFIGURATION
# ==============================================================================

app_service_sku       = "P1v3"     # Basic tier for dev (cost-effective)
app_service_always_on = true    # Can be false for dev to save costs

# ==============================================================================
# RUNTIME CONFIGURATION
# ==============================================================================

# runtime_stack  = "dotnet"
# dotnet_version = "8.0"

# Alternative runtimes (uncomment as needed):
runtime_stack = "node"
node_version  = "20-lts"
#
# runtime_stack  = "python"
# python_version = "3.12"

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

enable_private_endpoint = true  
https_only              = true   # Always enforce HTTPS
minimum_tls_version     = "1.2"  # Minimum TLS 1.2
ftps_state              = "Disabled"  # Disable FTP/FTPS

# ==============================================================================
# PERFORMANCE SETTINGS
# ==============================================================================

http2_enabled      = true
websockets_enabled = false  # Enable if needed for real-time features

# ==============================================================================
# CORS CONFIGURATION
# ==============================================================================

cors_allowed_origins = [
  # "http://localhost:3000",
  # "http://localhost:5000",
  # "http://localhost:5173",  # Vite dev server
  # # Add additional dev origins as needed
]

cors_support_credentials = false

# ==============================================================================
# HEALTH CHECK CONFIGURATION
# ==============================================================================

health_check_path          = "/health"
health_check_eviction_time = 2

# ==============================================================================
# AUTO-HEAL CONFIGURATION
# ==============================================================================

enable_auto_heal                         = false  # Disable for dev
auto_heal_action_type                    = "Recycle"
auto_heal_trigger_requests_count         = 70
auto_heal_trigger_requests_interval      = "00:01:00"
auto_heal_minimum_process_execution_time = "00:01:00"

# ==============================================================================
# MONITORING CONFIGURATION
# ==============================================================================

enable_diagnostics = true

diagnostic_log_categories = [
  "AppServiceHTTPLogs",
  "AppServiceConsoleLogs",
  "AppServiceAppLogs",
  "AppServiceAuditLogs"
]

# ==============================================================================
# DEPLOYMENT SLOT CONFIGURATION
# ==============================================================================

create_staging_slot = false  # Not needed for dev
staging_slot_name   = "staging"

# ==============================================================================
# AUTOSCALING CONFIGURATION
# ==============================================================================

enable_autoscale           = false  # Not needed for dev
autoscale_min_capacity     = 1
autoscale_max_capacity     = 2
autoscale_default_capacity = 1
autoscale_cpu_threshold_up   = 70
autoscale_cpu_threshold_down = 30

# ==============================================================================
# ALERTING CONFIGURATION
# ==============================================================================

# enable_alerts                 = false  # Alerts not needed for dev
# alert_action_group_id         = null
# alert_cpu_threshold           = 80
# alert_memory_threshold        = 85
# alert_response_time_threshold = 10
# alert_http_errors_threshold   = 20

# ==============================================================================
# IP RESTRICTIONS
# ==============================================================================

# No IP restrictions for dev (allow all traffic)
ip_restrictions = []

# Restrict SCM (Kudu) access to specific IPs if needed
scm_ip_restrictions = [
  # Example: Restrict to office IP
  # {
  #   name       = "AllowOfficeIP"
  #   ip_address = "203.0.113.0/24"
  #   priority   = 100
  #   action     = "Allow"
  # }
]

# ==============================================================================
# APPLICATION SETTINGS
# ==============================================================================

additional_app_settings = {
  "ASPNETCORE_ENVIRONMENT"              = "Development"
  "ASPNETCORE_DETAILEDERRORS"          = "true"
  "Logging__LogLevel__Default"          = "Debug"
  "Logging__LogLevel__Microsoft"        = "Information"
  
  # Frontend-specific settings
  "API_BASE_URL"                        = "https://api-dev.example.com"
  "ENABLE_SWAGGER"                      = "true"
  
  # Add additional development-specific settings here
}

# ==============================================================================
# CONNECTION STRINGS
# ==============================================================================

# Connection strings (if needed)
connection_strings = []

# Example:
# connection_strings = [
#   {
#     name  = "DefaultConnection"
#     type  = "SQLAzure"
#     value = "@Microsoft.KeyVault(SecretUri=https://kv-example.vault.azure.net/secrets/db-connection)"
#   }
# ]

# ==============================================================================
# STICKY SETTINGS
# ==============================================================================

# Settings that should NOT be swapped during slot swap
# sticky_app_setting_names = [
#   "ASPNETCORE_ENVIRONMENT"
# ]

# sticky_connection_string_names = []

