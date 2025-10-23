module "common" {
  source = "../common"
}

module "naming_bastion" {
  source        = "../naming"
  resource_type = module.common.resource_types.bastion_host
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

module "naming_public_ip" {
  source        = "../naming"
  resource_type = module.common.resource_types.public_ip
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion" {
  name                = module.naming_public_ip.name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Bastion Host
resource "azurerm_bastion_host" "this" {
  name                = module.naming_bastion.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# RBAC assignments for Bastion
resource "azurerm_role_assignment" "bastion_admin" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_bastion_host.this.id
  role_definition_name  = "Bastion Host Reader"
  principal_id         = var.admin_object_ids[count.index]
}

resource "azurerm_role_assignment" "bastion_reader" {
  count                = length(var.reader_object_ids)
  scope                = azurerm_bastion_host.this.id
  role_definition_name  = "Bastion Host Reader"
  principal_id         = var.reader_object_ids[count.index]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "bastion" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag"
  target_resource_id         = azurerm_bastion_host.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "BastionAuditLogs"
  }
}
