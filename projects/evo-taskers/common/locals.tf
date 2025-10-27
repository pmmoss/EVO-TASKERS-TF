# Common locals for the landing zone
locals {
  # Project metadata
  project     = var.project
  environment = var.environment
  location    = var.location
  location_short = var.location_short

  
  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    Location    = var.location
    ManagedBy   = "Terraform"
    CreatedBy   = "Patrick Moss"
    Tier        = "Landing Zone"
  })
  
  # Network configuration
  vnet_address_space = var.vnet_address_space
  subnet_configs = {
    app_service_integration = {
      name           = "snet-app-integration"
      address_prefix = cidrsubnet(var.vnet_address_space[0], 8, 1)
      purpose        = "AppServiceIntegration"
    }
    private_endpoints = {
      name           = "snet-private-endpoints"
      address_prefix = cidrsubnet(var.vnet_address_space[0], 8, 2)
      purpose        = "PrivateEndpoints"
    }
    gateway = {
      name           = "snet-gateway"
      address_prefix = cidrsubnet(var.vnet_address_space[0], 8, 3)
      purpose        = "Gateway"
    }
    bastion = {
      name           = "AzureBastionSubnet"
      address_prefix = cidrsubnet(var.vnet_address_space[0], 8, 4)
      purpose        = "Bastion"
    }
  }
  

}
