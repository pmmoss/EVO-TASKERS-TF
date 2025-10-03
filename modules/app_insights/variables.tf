variable "project" { 
  type        = string
  description = "Project short name"
}
variable "environment" { 
  type        = string
  description = "Environment name (dev, test, prod)"
}
variable "location" { 
  type        = string
  description = "Azure region short name (e.g., wus2)"
}
variable "location_short" { 
  type        = string
  description = "Azure region short name (e.g., wus2)"
}
variable "resource_group_name" { 
  type        = string
  description = "Name of the resource group"
}
variable "application_type" {
  type = string
  description = "Application Insights application type"
  default = "web"
}

variable "log_analytics_workspace_id" {
  type = string
  description = "Log Analytics workspace ID"
}

variable "subnet_id" {
  type = string
  description = "Subnet ID for private endpoint"
}

variable "enable_private_endpoint" {
  type = bool
  description = "Enable private endpoint"
  default = true
}

variable "admin_object_ids" {
  type = list(string)
  description = "List of object IDs for Application Insights administrators"
  default = []
}

variable "reader_object_ids" {
  type = list(string)
  description = "List of object IDs for Application Insights readers"
  default = []
}

variable "enable_diagnostics" {
  type = bool
  description = "Enable diagnostic settings"
  default = true
}

variable "tags" { 
  type        = map(string)
  description = "Resource tags"
  default     = {}
}
