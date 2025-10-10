# ==============================================================================
# APP SERVICE OUTPUTS
# ==============================================================================

output "app_service_id" {
  value       = azurerm_linux_web_app.this.id
  description = "The ID of the Linux Web App"
}

output "app_service_name" {
  value       = azurerm_linux_web_app.this.name
  description = "The name of the Linux Web App"
}

output "app_service_default_hostname" {
  value       = azurerm_linux_web_app.this.default_hostname
  description = "The default hostname of the Linux Web App"
}

output "app_service_default_site_hostname" {
  value       = "https://${azurerm_linux_web_app.this.default_hostname}"
  description = "The default site URL with HTTPS"
}

output "app_service_outbound_ip_addresses" {
  value       = azurerm_linux_web_app.this.outbound_ip_addresses
  description = "Comma-separated list of outbound IP addresses"
}

output "app_service_possible_outbound_ip_addresses" {
  value       = azurerm_linux_web_app.this.possible_outbound_ip_addresses
  description = "Comma-separated list of possible outbound IP addresses"
}

output "app_service_kind" {
  value       = azurerm_linux_web_app.this.kind
  description = "The kind of the Linux Web App"
}

output "app_service_custom_domain_verification_id" {
  value       = azurerm_linux_web_app.this.custom_domain_verification_id
  description = "Custom domain verification ID for the app"
}

# ==============================================================================
# IDENTITY OUTPUTS
# ==============================================================================

output "app_service_identity_principal_id" {
  value       = try(azurerm_linux_web_app.this.identity[0].principal_id, null)
  description = "The principal ID of the system-assigned managed identity (if enabled)"
}

output "app_service_identity_tenant_id" {
  value       = try(azurerm_linux_web_app.this.identity[0].tenant_id, null)
  description = "The tenant ID of the system-assigned managed identity (if enabled)"
}

output "app_service_identity_type" {
  value       = azurerm_linux_web_app.this.identity[0].type
  description = "The type of managed identity configured"
}

output "app_service_identity_identity_ids" {
  value       = try(azurerm_linux_web_app.this.identity[0].identity_ids, [])
  description = "The list of user-assigned managed identity IDs"
}

# ==============================================================================
# SERVICE PLAN OUTPUTS
# ==============================================================================

output "service_plan_id" {
  value       = var.create_service_plan ? azurerm_service_plan.this[0].id : var.existing_service_plan_id
  description = "The ID of the App Service Plan"
}

output "service_plan_name" {
  value       = var.create_service_plan ? azurerm_service_plan.this[0].name : null
  description = "The name of the App Service Plan (null if using existing)"
}

output "service_plan_kind" {
  value       = var.create_service_plan ? azurerm_service_plan.this[0].kind : null
  description = "The kind of the App Service Plan"
}

output "service_plan_reserved" {
  value       = var.create_service_plan ? azurerm_service_plan.this[0].reserved : null
  description = "Whether the App Service Plan is reserved (Linux)"
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "private_endpoint_id" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.app_service[0].id : null
  description = "The ID of the private endpoint (if enabled)"
}

output "private_endpoint_private_ip" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.app_service[0].private_service_connection[0].private_ip_address : null
  description = "The private IP address of the private endpoint (if enabled)"
}

output "private_endpoint_network_interface_id" {
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.app_service[0].network_interface[0].id : null
  description = "The network interface ID of the private endpoint (if enabled)"
}

output "vnet_integration_subnet_id" {
  value       = var.enable_vnet_integration ? var.subnet_id : null
  description = "The subnet ID used for VNet integration"
}

# ==============================================================================
# DEPLOYMENT SLOT OUTPUTS
# ==============================================================================

output "staging_slot_id" {
  value       = var.create_staging_slot ? azurerm_linux_web_app_slot.staging[0].id : null
  description = "The ID of the staging slot (if enabled)"
}

output "staging_slot_name" {
  value       = var.create_staging_slot ? azurerm_linux_web_app_slot.staging[0].name : null
  description = "The name of the staging slot (if enabled)"
}

output "staging_slot_default_hostname" {
  value       = var.create_staging_slot ? azurerm_linux_web_app_slot.staging[0].default_hostname : null
  description = "The default hostname of the staging slot (if enabled)"
}

# ==============================================================================
# CUSTOM DOMAIN OUTPUTS
# ==============================================================================

output "custom_domain_bindings" {
  value = var.custom_domains != [] ? [
    for idx, domain in var.custom_domains : {
      hostname       = domain.hostname
      binding_id     = azurerm_app_service_custom_hostname_binding.this[idx].id
      certificate_id = azurerm_app_service_certificate_binding.this[idx].certificate_id
    }
  ] : []
  description = "Custom domain bindings"
}

# ==============================================================================
# MONITORING OUTPUTS
# ==============================================================================

output "diagnostic_setting_id" {
  value       = var.enable_diagnostics ? azurerm_monitor_diagnostic_setting.app_service[0].id : null
  description = "The ID of the diagnostic setting (if enabled)"
}

output "autoscale_setting_id" {
  value       = var.enable_autoscale && var.create_service_plan ? azurerm_monitor_autoscale_setting.this[0].id : null
  description = "The ID of the autoscale setting (if enabled)"
}

output "cpu_alert_id" {
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.cpu_alert[0].id : null
  description = "The ID of the CPU alert rule (if enabled)"
}

output "memory_alert_id" {
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.memory_alert[0].id : null
  description = "The ID of the memory alert rule (if enabled)"
}

output "response_time_alert_id" {
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.response_time_alert[0].id : null
  description = "The ID of the response time alert rule (if enabled)"
}

output "http_errors_alert_id" {
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.http_errors_alert[0].id : null
  description = "The ID of the HTTP errors alert rule (if enabled)"
}

# ==============================================================================
# SITE CONFIG OUTPUTS
# ==============================================================================

output "site_config" {
  value = {
    always_on             = var.always_on
    minimum_tls_version   = var.minimum_tls_version
    ftps_state            = var.ftps_state
    http2_enabled         = var.http2_enabled
    websockets_enabled    = var.websockets_enabled
    health_check_path     = var.health_check_path
    runtime_stack         = var.runtime_stack
  }
  description = "Site configuration summary"
}

# ==============================================================================
# COMPREHENSIVE OUTPUT
# ==============================================================================

output "app_service_details" {
  value = {
    id                     = azurerm_linux_web_app.this.id
    name                   = azurerm_linux_web_app.this.name
    default_hostname       = azurerm_linux_web_app.this.default_hostname
    default_site_url       = "https://${azurerm_linux_web_app.this.default_hostname}"
    resource_group_name    = var.resource_group_name
    location               = var.location
    kind                   = azurerm_linux_web_app.this.kind
    service_plan_id        = var.create_service_plan ? azurerm_service_plan.this[0].id : var.existing_service_plan_id
    https_only             = var.https_only
    identity_type          = azurerm_linux_web_app.this.identity[0].type
    principal_id           = try(azurerm_linux_web_app.this.identity[0].principal_id, null)
    private_endpoint_enabled = var.enable_private_endpoint
    vnet_integration_enabled = var.enable_vnet_integration
    staging_slot_created  = var.create_staging_slot
  }
  description = "Comprehensive details about the Linux Web App"
}
