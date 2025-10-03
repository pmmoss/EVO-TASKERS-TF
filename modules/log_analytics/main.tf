module "common" {
  source = "../common"
}

module "naming_log_analytics" {
  source        = "../naming"
  resource_type = module.common.resource_types.log_analytics_workspace
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = module.naming_log_analytics.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

# RBAC assignments for Log Analytics
resource "azurerm_role_assignment" "log_analytics_admin" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = var.admin_object_ids[count.index]
}

resource "azurerm_role_assignment" "log_analytics_reader" {
  count                = length(var.reader_object_ids)
  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.reader_object_ids[count.index]
}

# Diagnostic settings for Log Analytics itself
resource "azurerm_monitor_diagnostic_setting" "log_analytics" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag"
  target_resource_id         = azurerm_log_analytics_workspace.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "Audit"
  }
}
