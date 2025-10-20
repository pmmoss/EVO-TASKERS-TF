variable "project" { 
  type = string 
  description = "Project name"
}

variable "environment" { 
  type = string 
  description = "Environment name (dev, qa, prod)"
}

variable "location" { 
  type = string 
  description = "Azure region"
}

variable "location_short" { 
  type = string 
  description = "Azure region short name (e.g., wus2)"
}
variable "vnet_address_space" {
  type = list(string)
  description = "Address space for the VNET"
  default = ["10.0.0.0/16"]
}

variable "hub_firewall_ip" {
  type = string
  description = "IP address of the hub firewall for default routing"
  default = ""
}

variable "admin_object_ids" {
  type = list(string)
  description = "List of object IDs for administrators"
  default = []
}

variable "reader_object_ids" {
  type = list(string)
  description = "List of object IDs for readers"
  default = []
}

variable "enable_key_vault_access_policy" {
  type = bool
  description = "Enable access policy for current user on Key Vault"
  default = false
}

variable "enable_bastion" {
  type = bool
  description = "Enable Bastion host for secure access"
  default = true
}

variable "logic_app_service_plan_name" {
  type = string
  description = "Name of the Logic App Service Plan"
  default = "logicapps"
}

variable "function_app_service_plan_name" {
  type = string
  description = "Name of the Function App Service Plan"
  default = "functions"
}

variable "logic_app_service_plan_sku" {
  type = string
  description = "SKU of the Logic App Service Plan"
  default = "WS1"
}

variable "function_app_service_plan_sku" {
  type = string
  description = "SKU of the Function App Service Plan"
  default = "Y1"
}

variable "logic_app_service_plan_existing_service_plan_id" {
  type = string
  description = "Existing Service Plan ID of the Logic App Service Plan"
  default = null
}

variable "function_app_service_plan_existing_service_plan_id" {
  type = string
  description = "Existing Service Plan ID of the Function App Service Plan"
  default = null
}


variable "tags" {
  type = map(string)
  description = "Common tags for all resources"
  default = {}
}
