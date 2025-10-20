# ==============================================================================
# APP SERVICE PLAN VARIABLES
# ==============================================================================
variable "project" {
  type        = string
  description = "Project name"
  default     = data.terraform_remote_state.common.outputs.project
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = data.terraform_remote_state.common.outputs.environment
}
variable "location" {
  type        = string
  description = "Azure region"
  default     = data.terraform_remote_state.common.outputs.location
}
variable "location_short" {
  type        = string
  description = "Short Azure region code"
  default     = data.terraform_remote_state.common.outputs.location_short
}
variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = data.terraform_remote_state.common.outputs.resource_group_name
}

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

