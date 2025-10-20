# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "project" {
  type        = string
  description = "Project name"
}

variable "plan_name" {
  type        = string
  description = "Name suffix for the App Service Plan (e.g., 'shared', 'functions', 'webapps')"
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

variable "os_type" {
  type        = string
  description = "Operating system type (Linux or Windows)"
  
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be either Linux or Windows"
  }
}

variable "sku_name" {
  type        = string
  description = "SKU name for the App Service Plan (e.g., B1, S1, P1V2, P1V3, Y1, EP1, WS1)"
}

# ==============================================================================
# OPTIONAL VARIABLES
# ==============================================================================

variable "custom_name" {
  type        = string
  description = "Custom name for the App Service Plan (overrides naming convention)"
  default     = null
}

variable "plan_purpose" {
  type        = string
  description = "Purpose of the App Service Plan (e.g., 'Shared Functions', 'Web Apps', 'Logic Apps')"
  default     = "App Hosting"
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
# TAGS
# ==============================================================================

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

