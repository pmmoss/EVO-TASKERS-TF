module "common" {
  source = "../common"
}

module "naming_appinsights" {
  source        = "../naming"
  resource_type = module.common.resource_types.application_insights
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

module "naming_pe" {
  source        = "../naming"
  resource_type = module.common.resource_types.private_endpoint
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

module "naming_psc" {
  source        = "../naming"
  resource_type = module.common.resource_types.private_service_connection
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

resource "azurerm_application_insights" "this" {
  name                = module.naming_appinsights.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  workspace_id        = var.log_analytics_workspace_id
  tags                = var.tags
}

# Private endpoint for Application Insights
# resource "azurerm_private_endpoint" "app_insights" {
#   count               = var.enable_private_endpoint ? 1 : 0
#   name                = "${module.naming_pe.name}-appi"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   subnet_id           = var.subnet_id
#   tags                = var.tags

#   private_service_connection {
#     name                           = "${module.naming_psc.name}-appi"
#     private_connection_resource_id  = azurerm_application_insights.this.id
#     is_manual_connection           = false
#     subresource_names              = ["api"]
#   }
# }

# RBAC assignments for Application Insights
resource "azurerm_role_assignment" "app_insights_admin" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_application_insights.this.id
  role_definition_name = "Application Insights Component Contributor"
  principal_id         = var.admin_object_ids[count.index]
}

resource "azurerm_role_assignment" "app_insights_reader" {
  count                = length(var.reader_object_ids)
  scope                = azurerm_application_insights.this.id
  role_definition_name = "Application Insights Component Reader"
  principal_id         = var.reader_object_ids[count.index]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "app_insights" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag"
  target_resource_id         = azurerm_application_insights.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppTraces"
  }

  enabled_log {
    category = "AppDependencies"
  }

  enabled_log {
    category = "AppRequests"
  }

  enabled_log {
    category = "AppExceptions"
  }
}
