# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "app_name" {
  type        = string
  description = "Application name (e.g., dashboardfrontend)"
}

# ==============================================================================
# APP SERVICE PLAN VARIABLES
# ==============================================================================

variable "app_service_sku" {
  type        = string
  description = "SKU name for the App Service Plan (e.g., B1, S1, P0v3, P1V3)"
  default     = "B1"
}

variable "app_service_always_on" {
  type        = bool
  description = "Keep the app always loaded (recommended for production)"
  default     = false
}

# ==============================================================================
# RUNTIME CONFIGURATION
# ==============================================================================

variable "runtime_stack" {
  type        = string
  description = "Runtime stack (dotnet, node, python, etc.)"
  default     = "dotnet"
}

variable "dotnet_version" {
  type        = string
  description = ".NET version (e.g., 6.0, 7.0, 8.0)"
  default     = "8.0"
}

variable "node_version" {
  type        = string
  description = "Node.js version (e.g., 16-lts, 18-lts, 20-lts)"
  default     = "20-lts"
}

variable "python_version" {
  type        = string
  description = "Python version (e.g., 3.9, 3.10, 3.11, 3.12)"
  default     = "3.12"
}

# ==============================================================================
# NETWORKING VARIABLES
# ==============================================================================

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint for inbound traffic (recommended for production)"
  default     = false
}

variable "https_only" {
  type        = bool
  description = "Require HTTPS for all requests"
  default     = true
}

variable "minimum_tls_version" {
  type        = string
  description = "Minimum TLS version (1.0, 1.1, 1.2, 1.3)"
  default     = "1.2"
}

variable "ftps_state" {
  type        = string
  description = "FTP/FTPS state (AllAllowed, FtpsOnly, Disabled)"
  default     = "Disabled"
}

variable "http2_enabled" {
  type        = bool
  description = "Enable HTTP/2"
  default     = true
}

variable "websockets_enabled" {
  type        = bool
  description = "Enable WebSockets support"
  default     = false
}

# ==============================================================================
# CORS CONFIGURATION
# ==============================================================================

variable "cors_allowed_origins" {
  type        = list(string)
  description = "List of allowed origins for CORS"
  default     = []
}

variable "cors_support_credentials" {
  type        = bool
  description = "Support credentials in CORS requests"
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
  description = "Health check eviction time in minutes (2-10)"
  default     = 2
}

# ==============================================================================
# AUTO-HEAL VARIABLES
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

variable "auto_heal_minimum_process_execution_time" {
  type        = string
  description = "Minimum process execution time before auto-heal (format: HH:MM:SS)"
  default     = "00:01:00"
}

# ==============================================================================
# MONITORING VARIABLES
# ==============================================================================

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings"
  default     = true
}

variable "diagnostic_log_categories" {
  type        = list(string)
  description = "List of log categories to enable"
  default = [
    "AppServiceHTTPLogs",
    "AppServiceConsoleLogs",
    "AppServiceAppLogs",
    "AppServiceAuditLogs"
  ]
}

# ==============================================================================
# DEPLOYMENT SLOT VARIABLES
# ==============================================================================

variable "create_staging_slot" {
  type        = bool
  description = "Create a staging deployment slot for blue-green deployments"
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
# AUTOSCALING VARIABLES
# ==============================================================================

variable "enable_autoscale" {
  type        = bool
  description = "Enable autoscaling for the App Service Plan"
  default     = false
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

variable "autoscale_default_capacity" {
  type        = number
  description = "Default instance count for autoscaling"
  default     = 1
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

# ==============================================================================
# APP SETTINGS VARIABLES
# ==============================================================================

variable "additional_app_settings" {
  type        = map(string)
  description = "Additional application settings"
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

variable "sticky_app_setting_names" {
  type        = list(string)
  description = "App setting names that should stick to the slot (not swapped)"
  default     = []
}

variable "sticky_connection_string_names" {
  type        = list(string)
  description = "Connection string names that should stick to the slot (not swapped)"
  default     = []
}

