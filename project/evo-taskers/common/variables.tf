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

# Service Plan Variables
variable "function_app_service_plan_name" {
  type = string
  description = "Name of the Windows Function App Service Plan"
  default = "functions-windows"
}

variable "function_app_service_plan_sku" {
  type = string
  description = "SKU for the Windows Function App Service Plan"
  default = "EP1"
}

variable "function_app_service_plan_existing_service_plan_id" {
  type = string
  description = "Existing service plan ID to use instead of creating new one"
  default = null
}

variable "logic_app_service_plan_name" {
  type = string
  description = "Name of the Logic App Service Plan"
  default = "logicapps"
}

variable "logic_app_service_plan_sku" {
  type = string
  description = "SKU for the Logic App Service Plan"
  default = "WS1"
}

variable "logic_app_service_plan_existing_service_plan_id" {
  type = string
  description = "Existing service plan ID to use instead of creating new one"
  default = null
}

variable "linux_web_app_service_plan_name" {
  type = string
  description = "Name of the Linux Web App Service Plan"
  default = "webapp-linux"
}

variable "linux_web_app_service_plan_sku" {
  type = string
  description = "SKU for the Linux Web App Service Plan"
  default = "S1"
}

variable "linux_web_app_service_plan_existing_service_plan_id" {
  type = string
  description = "Existing service plan ID to use instead of creating new one"
  default = null
}

variable "tags" {
  type = map(string)
  description = "Common tags for all resources"
  default = {}
}

variable "security_settings" {
  type = object({
    enable_private_endpoints = bool
    enable_public_access    = bool
    enable_rbac             = bool
    enable_diagnostics      = bool
    min_tls_version         = string
  })
  description = "Security settings for the landing zone"
  default = {
    enable_private_endpoints = true
    enable_public_access    = false
    enable_rbac             = true
    enable_diagnostics      = true
    min_tls_version         = "TLS1_2"
  }
}
