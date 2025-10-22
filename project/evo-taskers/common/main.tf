

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group
  location = var.location
  tags     = local.common_tags
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
  
  suffix = [local.project, local.environment, local.location_short]
}

# Log Analytics Workspace (created first as it's needed by other resources)
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4"
  
  name                = module.naming.log_analytics_workspace
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Workspace configuration
  sku               = "PerGB2018"
  retention_in_days = 30
  
  # Security settings
  public_network_access_enabled = !local.security_settings.enable_private_endpoints
  
  # Private endpoint (conditional)
  private_endpoints = local.security_settings.enable_private_endpoints ? {
    primary = {
      name                          = "${module.naming.log_analytics_workspace}-pe"
      subnet_resource_id            = module.network.private_endpoints_subnet_id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings (will be configured separately to avoid circular reference)
  diagnostic_settings = {}
  
  # Tags
  tags = local.common_tags
}

# Virtual Network
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.15"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Address space
  address_space = [local.vnet_address_space]
  
  # Subnets
  subnets = {
    app_service_integration = {
      name             = local.subnet_configs.app_service_integration.name
      address_prefixes = [local.subnet_configs.app_service_integration.address_prefix]
    }
    private_endpoints = {
      name             = local.subnet_configs.private_endpoints.name
      address_prefixes = [local.subnet_configs.private_endpoints.address_prefix]
    }
    gateway = {
      name             = local.subnet_configs.gateway.name
      address_prefixes = [local.subnet_configs.gateway.address_prefix]
    }
    bastion = {
      name             = local.subnet_configs.bastion.name
      address_prefixes = [local.subnet_configs.bastion.address_prefix]
    }
  }
  
  # Tags
  tags = local.common_tags
}

# Network Security Group for App Service Integration subnet
module "nsg_app_integration" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"
  
  name                = "${module.naming.network_security_group}-app-integration"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Security rules
  security_rules = {
    allow_https_outbound = {
      name                       = "AllowHTTPSOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    allow_http_outbound = {
      name                       = "AllowHTTPOutbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
  
  # Tags
  tags = local.common_tags
}

# Associate NSG with App Service Integration subnet
resource "azurerm_subnet_network_security_group_association" "app_integration" {
  subnet_id                 = module.vnet.subnets["app_service_integration"].id
  network_security_group_id = module.nsg_app_integration.id
}

# User-assigned Managed Identity for workloads
resource "azurerm_user_assigned_identity" "workload" {
  name                = "umi-${local.project}-${local.environment}-${local.location_short}"
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Key Vault
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10"
  
  name                = module.naming.key_vault
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # SKU configuration
  sku_name = "standard"
  
  # Security settings
  public_network_access_enabled = !local.security_settings.enable_private_endpoints
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  # Access policies (if enabled)
  access_policy = var.enable_key_vault_access_policy ? {
    admin_policy = {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = var.admin_object_ids[0]
      key_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
      ]
      certificate_permissions = [
        "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
      ]
    }
  } : {}
  
  # Private endpoint (conditional)
  private_endpoints = local.security_settings.enable_private_endpoints ? {
    primary = {
      name                          = "${module.naming.key_vault}-pe"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings
  diagnostic_settings = local.security_settings.enable_diagnostics ? {
    key_vault_diagnostics = {
      name                  = "diag-${module.naming.key_vault}"
      workspace_resource_id = module.log_analytics.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  
  # Tags
  tags = local.common_tags
}

# Storage Account
module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.6"
  
  name                = module.naming.storage_account
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Account configuration
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  
  # Security settings
  public_network_access_enabled = !local.security_settings.enable_private_endpoints
  
  # Network rules
  network_rules = local.security_settings.enable_private_endpoints ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [
      module.vnet.subnets["private_endpoints"].id,
      module.vnet.subnets["app_service_integration"].id
    ]
  } : {
    default_action = "Allow"
  }
  
  # Private endpoint (conditional)
  private_endpoints = local.security_settings.enable_private_endpoints ? {
    primary = {
      name                          = "${module.naming.storage_account}-pe"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings
  diagnostic_settings = local.security_settings.enable_diagnostics ? {
    storage_diagnostics = {
      name                  = "diag-${module.naming.storage_account}"
      workspace_resource_id = module.log_analytics.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  
  # Tags
  tags = local.common_tags
}

# RBAC: grant UAMI access to Key Vault and Storage
resource "azurerm_role_assignment" "umi_kv_secrets_user" {
  scope                = module.key_vault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "umi_storage_blob_contributor" {
  scope                = module.storage.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# Application Insights
module "app_insights" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "~> 0.4"
  
  name                = module.naming.application_insights
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Application type
  application_type = "web"
  
  # Workspace configuration
  workspace_resource_id = module.log_analytics.id
  
  # Security settings
  public_network_access_enabled = !local.security_settings.enable_private_endpoints
  
  # Private endpoint (conditional)
  private_endpoints = local.security_settings.enable_private_endpoints ? {
    primary = {
      name                          = "${module.naming.application_insights}-pe"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].id
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } : {}
  
  # Diagnostic settings
  diagnostic_settings = local.security_settings.enable_diagnostics ? {
    app_insights_diagnostics = {
      name                  = "diag-${module.naming.application_insights}"
      workspace_resource_id = module.log_analytics.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  
  # Tags
  tags = local.common_tags
}


# Bastion Host (optional)
module "bastion" {
  count = var.enable_bastion ? 1 : 0
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.8"
  
  name                = module.naming.bastion_host
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Subnet configuration
  subnet_resource_id = module.vnet.subnets["bastion"].id
  
  # SKU configuration
  sku = "Standard"
  
  # Diagnostic settings
  diagnostic_settings = local.security_settings.enable_diagnostics ? {
    bastion_diagnostics = {
      name                  = "diag-${module.naming.bastion_host}"
      workspace_resource_id = module.log_analytics.id
      log_groups            = ["allLogs"]
      metric_categories     = ["AllMetrics"]
    }
  } : {}
  
  # Tags
  tags = local.common_tags
}

# Windows Function App Service Plan
resource "azurerm_service_plan" "windows_function" {
  count = var.function_app_service_plan_existing_service_plan_id == null ? 1 : 0
  
  name                = "${module.naming.app_service_plan}-${var.function_app_service_plan_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  os_type             = "Windows"
  sku_name            = var.function_app_service_plan_sku
  
  # Tags
  tags = local.common_tags
}

# Logic App Service Plan
resource "azurerm_service_plan" "logic_app" {
  count = var.logic_app_service_plan_existing_service_plan_id == null ? 1 : 0
  
  name                = "${module.naming.app_service_plan}-${var.logic_app_service_plan_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  os_type             = "Windows"
  sku_name            = var.logic_app_service_plan_sku
  
  # Tags
  tags = local.common_tags
}

# Linux Web App Service Plan
resource "azurerm_service_plan" "linux_web_app" {
  count = var.linux_web_app_service_plan_existing_service_plan_id == null ? 1 : 0
  
  name                = "${module.naming.app_service_plan}-${var.linux_web_app_service_plan_name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  os_type             = "Linux"
  sku_name            = var.linux_web_app_service_plan_sku
  
  # Tags
  tags = local.common_tags
}
