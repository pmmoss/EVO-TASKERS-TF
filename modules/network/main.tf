# VNET with comprehensive network setup
module "common" {
  source = "../common"
}

module "naming_vnet" {
  source        = "../naming"
  resource_type = module.common.resource_types.virtual_network
  project       = var.project
  environment   = var.environment
  location      = var.location
  location_short = var.location_short
}

resource "azurerm_virtual_network" "this" {
  name                = module.naming_vnet.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "app_integration" {
  name                 = var.subnets[0].name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnets[0].address_prefix]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = var.subnets[1].name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnets[1].address_prefix]
  
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Insights"
  ]
}

resource "azurerm_subnet" "gateway" {
  name                 = var.subnets[2].name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnets[2].address_prefix]
}

resource "azurerm_subnet" "bastion" {
  name                 = var.subnets[3].name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnets[3].address_prefix]
}

# Network Security Group for App Service Integration subnet
resource "azurerm_network_security_group" "app_integration" {
  name                = "nsg-app-integration"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowAppServiceInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AppService"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppServiceOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AppService"
  }
}

# Network Security Group for Private Endpoints subnet
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowPrivateEndpointInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Gateway subnet
resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "app_integration" {
  subnet_id                 = azurerm_subnet.app_integration.id
  network_security_group_id = azurerm_network_security_group.app_integration.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# Route Table for default route to hub (only if hub_firewall_ip is provided)
resource "azurerm_route_table" "default" {
  count               = var.hub_firewall_ip != "" ? 1 : 0
  name                = "rt-default"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route {
    name           = "DefaultRoute"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_ip
  }
}

# Associate route table with subnets (only if route table exists)
resource "azurerm_subnet_route_table_association" "app_integration" {
  count          = var.hub_firewall_ip != "" ? 1 : 0
  subnet_id      = azurerm_subnet.app_integration.id
  route_table_id = azurerm_route_table.default[0].id
}

resource "azurerm_subnet_route_table_association" "private_endpoints" {
  count          = var.hub_firewall_ip != "" ? 1 : 0
  subnet_id      = azurerm_subnet.private_endpoints.id
  route_table_id = azurerm_route_table.default[0].id
}

resource "azurerm_subnet_route_table_association" "gateway" {
  count          = var.hub_firewall_ip != "" ? 1 : 0
  subnet_id      = azurerm_subnet.gateway.id
  route_table_id = azurerm_route_table.default[0].id
}
