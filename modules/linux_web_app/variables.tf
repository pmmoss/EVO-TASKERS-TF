# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "project" {
  type        = string
  description = "Project name"
}

variable "app_name" {
  type        = string
  description = "Application name (e.g., unlockbookings, dashboard)"
}

variable "environment" {
  type        = string
  description = "Environment (dev, qa, prod)"
  
  validation {
    condition     = contains(["dev", "qa", "prod", "staging", "test"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod, staging, test"
  }
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "location_short" {
  type        = string
  description = "Short name for Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

# ==============================================================================
# APP SERVICE PLAN VARIABLES
# ==============================================================================

variable "create_service_plan" {
  type        = bool
  description = "Whether to create a new App Service Plan or use an existing one"
  default     = true
}

variable "existing_service_plan_id" {
  type        = string
  description = "ID of existing App Service Plan (required if create_service_plan is false)"
  default     = null
}

variable "sku_name" {
  type        = string
  description = "SKU name for the App Service Plan (e.g., B1, S1, P1V2, P1V3)"
  default     = "B1"
  
  # validation {
  #   condition     = can(regex("^(B[1-3]|S[1-3]|P[1-3]V[2-3]|I[1-3]V[1-2]|WS[1-3]|Y1|EP[1-3])$", var.sku_name))
  #   error_message = "SKU name must be a valid App Service Plan SKU"
  # }
}

variable "zone_redundant" {
  type        = bool
  description = "Enable zone redundancy for the App Service Plan (Premium SKUs only)"
  default     = false
}

variable "per_site_scaling_enabled" {
  type        = bool
  description = "Enable per-site scaling on the App Service Plan"
  default     = false
}

variable "worker_count" {
  type        = number
  description = "Number of workers for the App Service Plan"
  default     = 1
  
  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 30
    error_message = "Worker count must be between 1 and 30"
  }
}

# ==============================================================================
# AUTOSCALING VARIABLES
# ==============================================================================

variable "enable_autoscale" {
  type        = bool
  description = "Enable autoscaling for the App Service Plan"
  default     = false
}

variable "autoscale_default_capacity" {
  type        = number
  description = "Default instance count for autoscaling"
  default     = 1
}

variable "autoscale_min_capacity" {
  type        = number
  description = "Minimum instance count for autoscaling"
  default     = 1
}

variable "autoscale_max_capacity" {
  type        = number
  description = "Maximum instance count for autoscaling"
  default     = 3
}

variable "autoscale_cpu_threshold_up" {
  type        = number
  description = "CPU percentage threshold to scale up"
  default     = 70
}

variable "autoscale_cpu_threshold_down" {
  type        = number
  description = "CPU percentage threshold to scale down"
  default     = 30
}

variable "autoscale_memory_threshold_up" {
  type        = number
  description = "Memory percentage threshold to scale up"
  default     = 80
}

# ==============================================================================
# IDENTITY VARIABLES
# ==============================================================================

variable "identity_type" {
  type        = string
  description = "Type of managed identity (SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned)"
  default     = "UserAssigned"
  
  validation {
    condition     = contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned"
  }
}

variable "user_assigned_identity_ids" {
  type        = list(string)
  description = "List of user-assigned managed identity IDs"
  default     = []
}

variable "user_assigned_identity_client_id" {
  type        = string
  description = "Client ID of the user-assigned managed identity"
  default     = null
}

variable "key_vault_reference_identity_id" {
  type        = string
  description = "Identity ID to use for Key Vault references"
  default     = null
}

# ==============================================================================
# MONITORING VARIABLES
# ==============================================================================

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string"
  sensitive   = true
  default     = null
}

variable "key_vault_uri" {
  type        = string
  description = "Key Vault URI for secret references"
  default     = null
}

# ==============================================================================
# NETWORKING VARIABLES
# ==============================================================================

variable "https_only" {
  type        = bool
  description = "Require HTTPS for all requests"
  default     = true
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access to the app"
  default     = true
}

variable "client_certificate_enabled" {
  type        = bool
  description = "Enable client certificate authentication"
  default     = false
}

variable "client_certificate_mode" {
  type        = string
  description = "Client certificate mode (Required, Optional, OptionalInteractiveUser)"
  default     = "Optional"
  
  validation {
    condition     = contains(["Required", "Optional", "OptionalInteractiveUser"], var.client_certificate_mode)
    error_message = "Client certificate mode must be Required, Optional, or OptionalInteractiveUser"
  }
}

variable "enable_vnet_integration" {
  type        = bool
  description = "Enable VNet integration for outbound traffic"
  default     = true
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for VNet integration"
  default     = null
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint for inbound traffic"
  default     = true
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint"
  default     = null
}

# ==============================================================================
# RUNTIME STACK VARIABLES
# ==============================================================================

variable "runtime_stack" {
  type        = string
  description = "Runtime stack (dotnet, node, python, java, ruby, php, go, docker)"
  default     = "dotnet"
  
  validation {
    condition     = contains(["dotnet", "node", "python", "java", "ruby", "php", "go", "docker"], var.runtime_stack)
    error_message = "Runtime stack must be one of: dotnet, node, python, java, ruby, php, go, docker"
  }
}

variable "dotnet_version" {
  type        = string
  description = ".NET version (e.g., 6.0, 7.0, 8.0)"
  default     = "8.0"
}

variable "node_version" {
  type        = string
  description = "Node version (e.g., 16-lts, 18-lts, 20-lts)"
  default     = "20-lts"
}

variable "python_version" {
  type        = string
  description = "Python version (e.g., 3.9, 3.10, 3.11, 3.12)"
  default     = "3.12"
}

variable "java_version" {
  type        = string
  description = "Java version (e.g., 11, 17, 21)"
  default     = "17"
}

variable "java_server" {
  type        = string
  description = "Java server (TOMCAT, JBOSSEAP, JAVA)"
  default     = "JAVA"
}

variable "java_server_version" {
  type        = string
  description = "Java server version (e.g., 10.0 for Tomcat, SE for Java)"
  default     = "SE"
}

variable "ruby_version" {
  type        = string
  description = "Ruby version (e.g., 2.7, 3.0)"
  default     = "3.0"
}

variable "php_version" {
  type        = string
  description = "PHP version (e.g., 8.0, 8.1, 8.2)"
  default     = "8.2"
}

variable "go_version" {
  type        = string
  description = "Go version (e.g., 1.19, 1.20)"
  default     = "1.20"
}

variable "docker_image_name" {
  type        = string
  description = "Docker image name (for container deployments)"
  default     = null
}

variable "docker_registry_url" {
  type        = string
  description = "Docker registry URL"
  default     = null
}

variable "docker_registry_username" {
  type        = string
  description = "Docker registry username"
  default     = null
  sensitive   = true
}

variable "docker_registry_password" {
  type        = string
  description = "Docker registry password"
  default     = null
  sensitive   = true
}

# ==============================================================================
# SITE CONFIG VARIABLES
# ==============================================================================

variable "minimum_tls_version" {
  type        = string
  description = "Minimum TLS version"
  default     = "1.3"
  
  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.minimum_tls_version)
    error_message = "TLS version must be 1.0, 1.1, 1.2, or 1.3"
  }
}

variable "always_on" {
  type        = bool
  description = "Keep the app always loaded (recommended for production)"
  default     = true
}

variable "ftps_state" {
  type        = string
  description = "FTP/FTPS state (AllAllowed, FtpsOnly, Disabled)"
  default     = "Disabled"
  
  validation {
    condition     = contains(["AllAllowed", "FtpsOnly", "Disabled"], var.ftps_state)
    error_message = "FTPS state must be AllAllowed, FtpsOnly, or Disabled"
  }
}

variable "http2_enabled" {
  type        = bool
  description = "Enable HTTP/2"
  default     = true
}

variable "websockets_enabled" {
  type        = bool
  description = "Enable WebSockets"
  default     = false
}

variable "use_32_bit_worker" {
  type        = bool
  description = "Use 32-bit worker process (false for production)"
  default     = false
}

variable "managed_pipeline_mode" {
  type        = string
  description = "Managed pipeline mode (Integrated, Classic)"
  default     = "Integrated"
  
  validation {
    condition     = contains(["Integrated", "Classic"], var.managed_pipeline_mode)
    error_message = "Managed pipeline mode must be Integrated or Classic"
  }
}

variable "remote_debugging_enabled" {
  type        = bool
  description = "Enable remote debugging"
  default     = false
}

variable "remote_debugging_version" {
  type        = string
  description = "Remote debugging version (VS2019, VS2022)"
  default     = "VS2022"
}

variable "local_mysql_enabled" {
  type        = bool
  description = "Enable local MySQL"
  default     = false
}

variable "container_registry_use_managed_identity" {
  type        = bool
  description = "Use managed identity for container registry authentication"
  default     = true
}

variable "container_registry_managed_identity_client_id" {
  type        = string
  description = "Client ID of managed identity for container registry"
  default     = null
}

variable "default_documents" {
  type        = list(string)
  description = "List of default documents"
  default     = []
}

variable "app_worker_count" {
  type        = number
  description = "Number of workers for the app"
  default     = null
}

variable "load_balancing_mode" {
  type        = string
  description = "Load balancing mode (LeastRequests, LeastResponseTime, RoundRobin, WeightedRoundRobin, WeightedTotalTraffic)"
  default     = "LeastRequests"
}

# ==============================================================================
# CORS VARIABLES
# ==============================================================================

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed origins for CORS"
  default     = []
}

variable "cors_support_credentials" {
  type        = bool
  description = "Support credentials in CORS requests"
  default     = false
}

# ==============================================================================
# IP RESTRICTION VARIABLES
# ==============================================================================

variable "ip_restrictions" {
  type = list(object({
    name                      = string
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
    priority                  = optional(number)
    action                    = optional(string)
    headers                   = optional(map(list(string)))
  }))
  description = "List of IP restrictions for the app"
  default     = []
}

variable "scm_ip_restrictions" {
  type = list(object({
    name                      = string
    ip_address                = optional(string)
    service_tag               = optional(string)
    virtual_network_subnet_id = optional(string)
    priority                  = optional(number)
    action                    = optional(string)
  }))
  description = "List of IP restrictions for SCM (Kudu) site"
  default     = []
}

variable "scm_use_main_ip_restriction" {
  type        = bool
  description = "Use main IP restrictions for SCM site"
  default     = false
}

# ==============================================================================
# HEALTH CHECK VARIABLES
# ==============================================================================

variable "health_check_path" {
  type        = string
  description = "Health check endpoint path"
  default     = null
}

variable "health_check_eviction_time" {
  type        = number
  description = "Health check eviction time in minutes"
  default     = 2
  
  validation {
    condition     = var.health_check_eviction_time >= 2 && var.health_check_eviction_time <= 10
    error_message = "Health check eviction time must be between 2 and 10 minutes"
  }
}

# ==============================================================================
# AUTO HEAL VARIABLES
# ==============================================================================

variable "enable_auto_heal" {
  type        = bool
  description = "Enable auto-heal functionality"
  default     = false
}

variable "auto_heal_action_type" {
  type        = string
  description = "Auto-heal action type (Recycle, LogEvent, CustomAction)"
  default     = "Recycle"
}

variable "auto_heal_minimum_process_execution_time" {
  type        = string
  description = "Minimum process execution time before auto-heal (format: HH:MM:SS)"
  default     = "00:01:00"
}

variable "auto_heal_trigger_requests_count" {
  type        = number
  description = "Request count trigger for auto-heal"
  default     = 70
}

variable "auto_heal_trigger_requests_interval" {
  type        = string
  description = "Request interval for auto-heal trigger (format: HH:MM:SS)"
  default     = "00:01:00"
}

variable "auto_heal_trigger_slow_request" {
  type = object({
    count      = number
    interval   = string
    time_taken = string
  })
  description = "Slow request trigger for auto-heal"
  default     = null
}

variable "auto_heal_trigger_status_codes" {
  type = list(object({
    count             = number
    interval          = string
    status_code_range = string
    sub_status        = optional(number)
    win32_status_code = optional(number)
  }))
  description = "Status code triggers for auto-heal"
  default     = []
}

# ==============================================================================
# APP SETTINGS VARIABLES
# ==============================================================================

variable "run_from_package" {
  type        = string
  description = "Run from package setting (0, 1, or URL)"
  default     = "1"
}

variable "enable_sync_update_site" {
  type        = string
  description = "Enable sync update site"
  default     = "true"
}

variable "additional_app_settings" {
  type        = map(string)
  description = "Additional app settings"
  default     = {}
}

variable "connection_strings" {
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  description = "Connection strings for the app"
  default     = []
  sensitive   = true
}

# variable "sticky_app_setting_names" {
#   type        = list(string)
#   description = "App setting names that should stick to the slot"
#   default     = []
# }

# variable "sticky_connection_string_names" {
#   type        = list(string)
#   description = "Connection string names that should stick to the slot"
#   default     = []
# }

# ==============================================================================
# AUTHENTICATION VARIABLES
# ==============================================================================

variable "enable_auth" {
  type        = bool
  description = "Enable authentication/authorization"
  default     = false
}

variable "auth_require_authentication" {
  type        = bool
  description = "Require authentication for all requests"
  default     = true
}

variable "auth_unauthenticated_action" {
  type        = string
  description = "Action for unauthenticated requests (RedirectToLoginPage, AllowAnonymous, Return401, Return403)"
  default     = "RedirectToLoginPage"
}

variable "auth_default_provider" {
  type        = string
  description = "Default authentication provider (AzureActiveDirectory, Facebook, Google, MicrosoftAccount, Twitter)"
  default     = "AzureActiveDirectory"
}

variable "auth_runtime_version" {
  type        = string
  description = "Authentication runtime version"
  default     = "~1"
}

variable "auth_login_enabled" {
  type        = bool
  description = "Enable login configuration"
  default     = true
}

variable "auth_token_store_enabled" {
  type        = bool
  description = "Enable token store"
  default     = true
}

variable "auth_token_refresh_extension_hours" {
  type        = number
  description = "Token refresh extension time in hours"
  default     = 72
}

variable "auth_preserve_url_fragments" {
  type        = bool
  description = "Preserve URL fragments for logins"
  default     = false
}

variable "auth_active_directory_enabled" {
  type        = bool
  description = "Enable Azure Active Directory authentication"
  default     = false
}

variable "auth_aad_client_id" {
  type        = string
  description = "Azure AD client ID"
  default     = null
  sensitive   = true
}

variable "auth_aad_tenant_auth_endpoint" {
  type        = string
  description = "Azure AD tenant auth endpoint"
  default     = null
}

variable "auth_aad_client_secret_setting_name" {
  type        = string
  description = "Name of app setting containing Azure AD client secret"
  default     = null
}

variable "auth_aad_allowed_audiences" {
  type        = list(string)
  description = "Allowed audiences for Azure AD authentication"
  default     = []
}

# ==============================================================================
# STORAGE ACCOUNT VARIABLES
# ==============================================================================

variable "storage_accounts" {
  type = list(object({
    name         = string
    type         = string
    account_name = string
    share_name   = string
    access_key   = string
    mount_path   = string
  }))
  description = "Storage accounts to mount"
  default     = []
  sensitive   = true
}

# ==============================================================================
# BACKUP VARIABLES
# ==============================================================================

variable "enable_backup" {
  type        = bool
  description = "Enable automatic backups"
  default     = false
}

variable "backup_storage_account_url" {
  type        = string
  description = "Storage account URL with SAS token for backups"
  default     = null
  sensitive   = true
}

variable "backup_frequency_interval" {
  type        = number
  description = "Backup frequency interval"
  default     = 1
}

variable "backup_frequency_unit" {
  type        = string
  description = "Backup frequency unit (Day, Hour)"
  default     = "Day"
}

variable "backup_keep_at_least_one" {
  type        = bool
  description = "Keep at least one backup"
  default     = true
}

variable "backup_retention_period_days" {
  type        = number
  description = "Backup retention period in days (1-30)"
  default     = 30
  
  validation {
    condition     = var.backup_retention_period_days >= 1 && var.backup_retention_period_days <= 30
    error_message = "Backup retention period must be between 1 and 30 days"
  }
}

variable "backup_start_time" {
  type        = string
  description = "Backup start time (ISO 8601 format)"
  default     = null
}

# ==============================================================================
# LOGGING VARIABLES
# ==============================================================================

variable "enable_detailed_logs" {
  type        = bool
  description = "Enable detailed logging configuration"
  default     = false
}

variable "logs_detailed_error_messages" {
  type        = bool
  description = "Enable detailed error messages"
  default     = true
}

variable "logs_failed_request_tracing" {
  type        = bool
  description = "Enable failed request tracing"
  default     = true
}

variable "logs_application_logs_enabled" {
  type        = bool
  description = "Enable application logs"
  default     = true
}

variable "logs_application_logs_file_system_level" {
  type        = string
  description = "Application logs file system level (Off, Error, Warning, Information, Verbose)"
  default     = "Information"
}

variable "logs_http_logs_enabled" {
  type        = bool
  description = "Enable HTTP logs"
  default     = true
}

variable "logs_http_logs_file_system_enabled" {
  type        = bool
  description = "Enable HTTP logs to file system"
  default     = true
}

variable "logs_http_logs_retention_days" {
  type        = number
  description = "HTTP logs retention in days"
  default     = 7
}

variable "logs_http_logs_retention_mb" {
  type        = number
  description = "HTTP logs retention in MB"
  default     = 35
}

# ==============================================================================
# DEPLOYMENT SLOT VARIABLES
# ==============================================================================

variable "create_staging_slot" {
  type        = bool
  description = "Create a staging deployment slot"
  default     = false
}

variable "staging_slot_name" {
  type        = string
  description = "Name of the staging slot"
  default     = "staging"
}

variable "staging_slot_app_settings" {
  type        = map(string)
  description = "App settings specific to staging slot (if null, uses production settings)"
  default     = null
}

# ==============================================================================
# CUSTOM DOMAIN VARIABLES
# ==============================================================================

variable "custom_domains" {
  type = list(object({
    hostname       = string
    certificate_id = string
    ssl_state      = string
  }))
  description = "Custom domains with SSL certificates"
  default     = []
}

# ==============================================================================
# DIAGNOSTICS VARIABLES
# ==============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics"
  default     = null
}

variable "diagnostics_storage_account_id" {
  type        = string
  description = "Storage account ID for diagnostics"
  default     = null
}

variable "diagnostics_eventhub_name" {
  type        = string
  description = "Event Hub name for diagnostics"
  default     = null
}

variable "diagnostics_eventhub_authorization_rule_id" {
  type        = string
  description = "Event Hub authorization rule ID for diagnostics"
  default     = null
}

variable "diagnostic_log_categories" {
  type        = list(string)
  description = "List of log categories to enable"
  default = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceAuditLogs",
    "AppServicePlatformLogs"
  ]
}

variable "diagnostic_metrics_enabled" {
  type        = bool
  description = "Enable diagnostic metrics"
  default     = true
}

# ==============================================================================
# ALERT VARIABLES
# ==============================================================================

variable "enable_alerts" {
  type        = bool
  description = "Enable metric alerts"
  default     = false
}

variable "alert_action_group_id" {
  type        = string
  description = "Action group ID for alerts"
  default     = null
}

variable "alert_cpu_threshold" {
  type        = number
  description = "CPU percentage threshold for alerts"
  default     = 80
}

variable "alert_memory_threshold" {
  type        = number
  description = "Memory percentage threshold for alerts"
  default     = 85
}

variable "alert_response_time_threshold" {
  type        = number
  description = "Response time threshold in seconds for alerts"
  default     = 5
}

variable "alert_http_errors_threshold" {
  type        = number
  description = "HTTP 5xx errors threshold for alerts"
  default     = 10
}

# ==============================================================================
# LIFECYCLE VARIABLES
# ==============================================================================

# variable "lifecycle_ignore_changes" {
#   type        = list(string)
#   description = "List of attributes to ignore in lifecycle"
#   default = [
#     "app_settings[\"WEBSITE_RUN_FROM_PACKAGE\"]",
#   ]
# }

# ==============================================================================
# TAGS
# ==============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
