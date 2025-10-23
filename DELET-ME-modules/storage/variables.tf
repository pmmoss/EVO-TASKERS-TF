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
variable "subnet_id" { 
  type        = string
  description = "Subnet ID for private endpoint"
}
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for diagnostics"
}
variable "admin_object_ids" {
  type = list(string)
  description = "List of object IDs for Storage administrators"
  default = []
}

variable "reader_object_ids" {
  type = list(string)
  description = "List of object IDs for Storage readers"
  default = []
}

variable "enable_network_rules" {
  type = bool
  description = "Enable network rules for storage account"
  default = true
}

variable "allowed_ip_rules" {
  type = list(string)
  description = "List of allowed IP addresses"
  default = []
}

variable "allowed_subnet_ids" {
  type = list(string)
  description = "List of allowed subnet IDs"
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
