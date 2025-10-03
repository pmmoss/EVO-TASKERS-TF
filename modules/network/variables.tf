variable "project" { 
  type = string 
  description = "Project name"
}

variable "environment" { 
  type = string 
  description = "Environment name (dev, qa, prod)"
}

variable "resource_group_name" { 
  type = string 
  description = "Name of the resource group"
}

variable "location" { 
  type = string 
  description = "Azure region for resources"
}

variable "location_short" { 
  type = string 
  description = "Azure region short name (e.g., wus2)"
}

variable "vnet_address_space" { 
  type = list(string) 
  description = "Address space for the VNET"
}

variable "subnets" {
  type = list(object({
    name          = string
    address_prefix = string
  }))
  description = "List of subnets to create"
}

variable "tags" { 
  type = map(string) 
  description = "Tags to apply to resources"
  default = {}
}

variable "hub_firewall_ip" {
  type = string
  description = "IP address of the hub firewall for default routing"
  default = ""
}
