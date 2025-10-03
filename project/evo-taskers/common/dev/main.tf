

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = module.naming_rg.name
  location = var.location
  tags     = local.common_tags
}

module "naming_rg" {
  source        = "../../../../modules/naming"
  resource_type = "rg"
  project       = local.project
  environment   = local.environment
  location      = local.location
  location_short = local.location_short
}

# Log Analytics Workspace (created first as it's needed by other resources)
module "log_analytics" {
  source = "../../../../modules/log_analytics"
  
  project                = local.project
  environment           = local.environment
  location              = local.location
  location_short        = local.location_short
  resource_group_name   = azurerm_resource_group.this.name
  sku                  = "PerGB2018"
  retention_in_days    = 30
  admin_object_ids     = var.admin_object_ids
  reader_object_ids    = var.reader_object_ids
  enable_diagnostics   = local.security_settings.enable_diagnostics
  tags                 = local.common_tags
}

# Network Infrastructure
module "network" {
  source = "../../../../modules/network"
  
  resource_group_name = azurerm_resource_group.this.name
  location           = local.location
  location_short     = local.location_short
  project            = local.project
  environment        = local.environment
  vnet_address_space = local.vnet_address_space
  subnets = [
    {
      name           = local.subnet_configs.app_service_integration.name
      address_prefix = local.subnet_configs.app_service_integration.address_prefix
    },
    {
      name           = local.subnet_configs.private_endpoints.name
      address_prefix = local.subnet_configs.private_endpoints.address_prefix
    },
    {
      name           = local.subnet_configs.gateway.name
      address_prefix = local.subnet_configs.gateway.address_prefix
    },
    {
      name           = local.subnet_configs.bastion.name
      address_prefix = local.subnet_configs.bastion.address_prefix
    }
  ]
  hub_firewall_ip = var.hub_firewall_ip
  tags            = local.common_tags
}

# Key Vault
module "key_vault" {
  source = "../../../../modules/keyvault"  
  
  project                      = local.project
  environment                 = local.environment
  location                    = local.location
  location_short              = local.location_short
  resource_group_name         = azurerm_resource_group.this.name
  subnet_id                   = module.network.private_endpoints_subnet_id
  log_analytics_workspace_id  = module.log_analytics.log_analytics_workspace_id
  admin_object_ids           = var.admin_object_ids
  reader_object_ids          = var.reader_object_ids
  enable_access_policy       = var.enable_key_vault_access_policy
  enable_diagnostics         = local.security_settings.enable_diagnostics
  tags                       = local.common_tags
}

# Storage Account
module "storage" {
  source = "../../../../modules/storage"
  
  project                    = local.project
  environment                = local.environment
  location                   = local.location
  location_short             = local.location_short
  resource_group_name        = azurerm_resource_group.this.name
  subnet_id                  = module.network.private_endpoints_subnet_id
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  admin_object_ids          = var.admin_object_ids
  reader_object_ids         = var.reader_object_ids
  enable_network_rules      = local.security_settings.enable_private_endpoints
  allowed_subnet_ids        = [module.network.private_endpoints_subnet_id]
  enable_diagnostics        = local.security_settings.enable_diagnostics
  tags                      = local.common_tags
}

# Application Insights
module "app_insights" {
  source = "../../../../modules/app_insights"
  project                     = local.project
  environment                = local.environment
  location                   = local.location
  location_short             = local.location_short
  resource_group_name        = azurerm_resource_group.this.name
  application_type           = "web"
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  subnet_id                  = module.network.private_endpoints_subnet_id
  enable_private_endpoint    = local.security_settings.enable_private_endpoints
  admin_object_ids          = var.admin_object_ids
  reader_object_ids         = var.reader_object_ids
  enable_diagnostics        = local.security_settings.enable_diagnostics
  tags                      = local.common_tags
}


# Bastion Host (optional)
module "bastion" {
  count = var.enable_bastion ? 1 : 0
  source = "../../../../modules/bastion"
  
  project                     = local.project
  environment                = local.environment
  location                   = local.location
  location_short             = local.location_short
  resource_group_name        = azurerm_resource_group.this.name
  subnet_id                  = module.network.bastion_subnet_id
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
  admin_object_ids          = var.admin_object_ids
  reader_object_ids         = var.reader_object_ids
  enable_diagnostics        = local.security_settings.enable_diagnostics
  tags                      = local.common_tags
}
