module "common" {
  source = "../common"
}

module "naming_storage" {
  source        = "../naming"
  resource_type = module.common.resource_types.storage_account
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

resource "azurerm_storage_account" "this" {
  name                     = module.naming_storage.storage_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_private_endpoint" "storage" {
  name                = "${module.naming_pe.name}-storage"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${module.naming_psc.name}-storage"
    private_connection_resource_id  = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  tags = var.tags
}

# Storage Account Network Rules
resource "azurerm_storage_account_network_rules" "this" {
  count = var.enable_network_rules ? 1 : 0
  
  storage_account_id = azurerm_storage_account.this.id
  
  default_action             = "Deny"
  ip_rules                   = var.allowed_ip_rules
  virtual_network_subnet_ids = var.allowed_subnet_ids
  bypass                     = ["AzureServices"]
}

# RBAC assignments for Storage Account
resource "azurerm_role_assignment" "storage_admin" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.admin_object_ids[count.index]
}

resource "azurerm_role_assignment" "storage_reader" {
  count                = length(var.reader_object_ids)
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.reader_object_ids[count.index]
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = "diag"
  target_resource_id         = azurerm_storage_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }
}
