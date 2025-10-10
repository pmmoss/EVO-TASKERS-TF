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

# variable "app_service_os_type" {
#   type = string
#   description = "App Service OS type (Linux or Windows)"
#   default = "Linux"
#   validation {
#     condition = contains(["Linux", "Windows"], var.app_service_os_type)
#     error_message = "App Service OS type must be either Linux or Windows."
#   }
# }

# variable "app_service_sku" {
#   type = string
#   description = "App Service Plan SKU"
#   default = "B1"
# }

# variable "app_service_always_on" {
#   type = bool
#   description = "Enable always on for App Service"
#   default = false
# }

# variable "app_service_settings" {
#   type = map(string)
#   description = "App Service application settings"
#   default = {}
# }

variable "tags" {
  type = map(string)
  description = "Common tags for all resources"
  default = {}
}
