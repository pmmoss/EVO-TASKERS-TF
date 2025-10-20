variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, qa, prod)"
  
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be dev, qa, or prod"
  }
}

# ==============================================================================
# APP SERVICE PLAN VARIABLES
# ==============================================================================

variable "windows_function_plan_sku" {
  type        = string
  description = "SKU for the shared Windows Function App Service Plan (Y1, EP1, EP2, EP3, P1V3, etc.)"
  default     = "EP1"
}

variable "windows_function_plan_enable_autoscale" {
  type        = bool
  description = "Enable autoscaling for the Windows Function App Service Plan"
  default     = false
}

variable "windows_function_plan_min_capacity" {
  type        = number
  description = "Minimum instance count for autoscaling"
  default     = 1
}

variable "windows_function_plan_max_capacity" {
  type        = number
  description = "Maximum instance count for autoscaling"
  default     = 5
}

variable "logic_app_plan_sku" {
  type        = string
  description = "SKU for the shared Logic App Service Plan (WS1, WS2, WS3)"
  default     = "WS1"
}

# ==============================================================================
# TAGS
# ==============================================================================

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to apply to shared resources"
  default     = {}
}

