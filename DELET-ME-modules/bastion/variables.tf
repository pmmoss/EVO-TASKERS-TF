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
  type = string
  description = "Subnet ID for Bastion (must be AzureBastionSubnet)"
}

variable "log_analytics_workspace_id" {
  type = string
  description = "Log Analytics workspace ID for diagnostics"
}

variable "admin_object_ids" {
  type = list(string)
  description = "List of object IDs for Bastion administrators"
  default = []
}

variable "reader_object_ids" {
  type = list(string)
  description = "List of object IDs for Bastion readers"
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
