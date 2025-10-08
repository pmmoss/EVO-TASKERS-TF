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

variable "sku_name" {
  type        = string
  description = "SKU name for the App Service Plan (e.g., B1, S1, P1V2)"
  default     = "B1"
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

variable "runtime_stack" {
  type        = string
  description = "Runtime stack (dotnet, node, python, java)"
  default     = "dotnet"
}

variable "dotnet_version" {
  type        = string
  description = ".NET version (e.g., 8.0)"
  default     = "8.0"
}

variable "node_version" {
  type        = string
  description = "Node version (e.g., 18-lts)"
  default     = "18-lts"
}

variable "python_version" {
  type        = string
  description = "Python version (e.g., 3.11)"
  default     = "3.11"
}

variable "java_version" {
  type        = string
  description = "Java version (e.g., 17)"
  default     = "17"
}

variable "java_server" {
  type        = string
  description = "Java server (e.g., TOMCAT, JAVA)"
  default     = "JAVA"
}

variable "java_server_version" {
  type        = string
  description = "Java server version (e.g., 10.0 for Tomcat)"
  default     = "SE"
}

variable "always_on" {
  type        = bool
  description = "Always on setting"
  default     = true
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

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed origins for CORS"
  default     = []
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
  default     = null
}

variable "health_check_eviction_time" {
  type        = number
  description = "Health check eviction time in minutes"
  default     = 2
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

