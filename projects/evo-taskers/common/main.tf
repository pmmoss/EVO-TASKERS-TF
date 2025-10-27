

# Data sources
data "azurerm_client_config" "current" {}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.2"
  
  suffix = [local.project, local.environment, local.location_short]
}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group
  location = var.location
  tags     = local.common_tags
}

# Virtual Network
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.15.0"
  
  name                = module.naming.virtual_network
  parent_id           = azurerm_resource_group.this.id
  location            = var.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Address space
  address_space = local.vnet_address_space
  
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

# Log Analytics Workspace (created first as it's needed by other resources)
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4.2"
  
  name                = module.naming.log_analytics_workspace
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Diagnostic settings (will be configured separately to avoid circular reference)
  diagnostic_settings = {}
  
  # Tags
  tags = local.common_tags
}

# Network Security Group for App Service Integration subnet
module "nsg_app_integration" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5.0"
  
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
  network_security_group_id = module.nsg_app_integration.outputs.network_security_group_id
}

# User-assigned Managed Identity for workloads
resource "azurerm_user_assigned_identity" "workload" {
  name                = module.naming.user_assigned_identity
  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Key Vault
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.10.2"
  
  name                = module.naming.key_vault
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # SKU configuration
  sku_name = "standard"
  
  # Security settings
  public_network_access_enabled = !var.security_settings.enable_private_endpoints
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  
  # Access policies (if enabled)

  
  # Private endpoint (conditional)
  private_endpoints = var.security_settings.enable_private_endpoints ? {
    primary = {
      name                          = "${module.naming.key_vault}-pe"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].id
      subresource_names             = ["vault"]
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  } :{}
  
  # Diagnostic settings
  diagnostic_settings = var.security_settings.enable_diagnostics ? {
    key_vault_diagnostics = {
      name                  = "diag-${module.log_analytics.name}"
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
  version = "~> 0.6.4"
  
  name                = module.naming.storage_account
  resource_group_name = module.naming.resource_group.name
  location            = var.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # Account configuration
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  
  # Security settings
  public_network_access_enabled = !var.security_settings.enable_private_endpoints
  
  # # Network rules
  # network_rules = var.security_settings.enable_private_endpoints ? {
  #   default_action             = "Deny"
  #   bypass                     = ["AzureServices"]
  #   virtual_network_subnet_ids = [
  #     module.vnet.subnets["private_endpoints"].id,
  #     module.vnet.subnets["app_service_integration"].id
  #   ]
  # } : {
  #   default_action = "Allow"
  # }
  
  # Private endpoint (conditional)
  private_endpoints = {
    primary = {
      name                          = "${module.naming.storage_account}-pe"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].id
      subresource_names             = ["blob"]
      private_dns_zone_resource_ids = [] # Managed externally or by policy
    }
  }
  
  
  # Tags
  tags = local.common_tags
}

# RBAC: grant UAMI access to Key Vault and Storage
resource "azurerm_role_assignment" "umi_kv_secrets_user" {
  scope                = module.key_vault.outputs.key_vault_id
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
  version = "~> 0.2.0"
  
  name                = module.naming.application_insights
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = module.log_analytics.resource_id
  location            = local.location

  enable_telemetry = true
}

# Bastion Host (conditional)
module "bastion" {
  count = var.enable_bastion ? 1 : 0
  
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "~> 0.8.1"
  
  name                = module.naming.bastion_host
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  
  # Enable telemetry for AVM (recommended)
  enable_telemetry = true
  
  # IP configuration
  ip_configuration = {
    subnet_id = module.vnet.subnets["bastion"].id
  }
  
  # Diagnostic settings
  diagnostic_settings = var.security_settings.enable_diagnostics ? {
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

module "avm-res-web-serverfarm_function_app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "0.8.0"

  location            = local.location
  name                = module.naming.app_service_plan.name_unique
  os_type             = "Windows"
  resource_group_name = azurerm_resource_group.this.name  
}

module "avm-res-web-serverfarm_logic_app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "0.8.0"

  location            = local.location
  name                = module.naming.app_service_plan.name_unique
  os_type             = "Windows"
  resource_group_name = azurerm_resource_group.this.name  
}

module "avm-res-web-serverfarm_linux_web_app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "0.8.0"

  location            = local.location
  name                = module.naming.app_service_plan.name_unique
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.this.name  
}