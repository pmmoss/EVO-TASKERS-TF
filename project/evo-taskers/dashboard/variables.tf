# Variables for AutomatedDataFeed (all environments)
# Environment-specific values are set in dev.tfvars, qa.tfvars, prod.tfvars

variable "app_name" {
  type        = string
  description = "Application name (e.g., unlockbookings, dashboard)"
  default     = "dashboard"
}

# App Service Configuration
variable "app_service_sku" {
  type        = string
  description = "App Service Plan SKU (e.g., B1, S1, P1V2)"
}

variable "app_service_always_on" {
  type        = bool
  description = "Enable always on for App Service (recommended for production)"
}

variable "runtime_stack" {
  type        = string
  description = "Runtime stack for App Service (dotnet, node, python, java)"
  default     = "dotnet"
}

variable "dotnet_version" {
  type        = string
  description = ".NET version (e.g., 8.0)"
  default     = "v8.0"
}

variable "health_check_path" {
  type        = string
  description = "Health check endpoint path"
  default     = "/health"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins"
  default     = []
}

variable "additional_app_settings" {
  type        = map(string)
  description = "Additional application settings"
  default     = {}
}

# Function App Configuration
variable "function_app_sku" {
  type        = string
  description = "Function App SKU (Y1 for Consumption, EP1 for Premium, B1/P0v3 for Basic)"
}

variable "function_app_always_on" {
  type        = bool
  description = "Enable always on for Function App (not available on Consumption plan)"
}

variable "functions_worker_runtime" {
  type        = string
  description = "Functions worker runtime (dotnet, node, python, java)"
  default     = "dotnet"
}

variable "additional_function_app_settings" {
  type        = map(string)
  description = "Additional function app settings"
  default     = {}
}

# Network Configuration
variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint for inbound traffic (recommended for production)"
}

