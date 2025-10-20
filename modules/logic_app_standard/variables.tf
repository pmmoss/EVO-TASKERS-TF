variable "project" {
  type        = string
  description = "Project name"
}

variable "app_name" {
  type        = string
  description = "Application name (e.g., unlockbookings, dashboard)"
}

variable "environment" {
  type        = string
  description = "Environment (dev, qa, prod)"
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

variable "create_service_plan" {
  type        = bool
  description = "Whether to create a new App Service Plan or use an existing one"
  default     = true
}

variable "existing_service_plan_id" {
  type        = string
  description = "ID of existing App Service Plan (required if create_service_plan is false)"
  default     = null
}

variable "sku_name" {
  type        = string
  description = "SKU name for the App Service Plan (e.g., WS1, WS2, WS3 for Workflow Standard). Only used if create_service_plan is true"
  default     = "WS1"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name for logic app"
}

variable "storage_account_access_key" {
  type        = string
  description = "Storage account access key"
  sensitive   = true
}

variable "storage_account_share_name" {
  type        = string
  description = "Storage account file share name for logic app"
  #default     = "logic-app-content"
}

variable "user_assigned_identity_id" {
  type        = string
  description = "ID of the user-assigned managed identity"
}

variable "user_assigned_identity_client_id" {
  type        = string
  description = "Client ID of the user-assigned managed identity"
}

variable "app_insights_connection_string" {
  type        = string
  description = "Application Insights connection string"
  sensitive   = true
}

variable "app_insights_instrumentation_key" {
  type        = string
  description = "Application Insights instrumentation key"
  sensitive   = true
}

variable "key_vault_uri" {
  type        = string
  description = "Key Vault URI for secret references"
}

variable "enable_vnet_integration" {
  type        = bool
  description = "Enable VNet integration"
  default     = true
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for VNet integration"
  default     = null
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private endpoint for inbound traffic"
  default     = false
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint"
  default     = null
}

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic settings"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostics"
  default     = null
}

variable "additional_app_settings" {
  type        = map(string)
  description = "Additional app settings"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "use_extension_bundle" {
  type        = bool
  description = "Enable extension bundle for Logic Apps"
  default     = true
}

variable "bundle_version" {
  type        = string
  description = "Extension bundle version range"
  default     = "[1.*, 2.0.0)"
}


