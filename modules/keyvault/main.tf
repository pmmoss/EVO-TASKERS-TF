module "common" {
  source = "../common"
}

module "naming_keyvault" {
  source        = "../naming"
  resource_type = module.common.resource_types.key_vault
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

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                        = module.naming_keyvault.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  public_network_access_enabled = false
  tags                       = var.tags
}

resource "azurerm_private_endpoint" "kv" {
  name                = "${module.naming_pe.name}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${module.naming_psc.name}-kv"
    private_connection_resource_id  = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
  tags = var.tags
}

# RBAC assignments for Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_ids[count.index]
}

resource "azurerm_role_assignment" "kv_reader" {
  count                = length(var.reader_object_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.reader_object_ids[count.index]
}

# Access policy for current user (fallback)
resource "azurerm_key_vault_access_policy" "current_user" {
  count        = var.enable_access_policy ? 1 : 0
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"
  ]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "kv" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }
}
