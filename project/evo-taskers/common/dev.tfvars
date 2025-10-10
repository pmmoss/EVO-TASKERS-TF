# Global Landing Zone Configuration
# This file contains the core infrastructure values for the landing zone

# Basic Configuration
project     = "pmoss-evotaskers"
environment = "dev"
location    = "West US 2"
location_short = "wus2"

# Network Configuration
vnet_address_space = ["10.1.0.0/16"]
hub_firewall_ip    = "" # Set this to your hub firewall IP when available

# Security Configuration - Add your actual object IDs
admin_object_ids = [
  # Add your admin object IDs here
  # Example: "00000000-0000-0000-0000-000000000000"
]

reader_object_ids = [
  # Add your reader object IDs here
]

# Key Vault Configuration
enable_key_vault_access_policy = true # Enable for initial setup, disable after RBAC is configured

# Bastion Configuration
enable_bastion = true

# Common Tags
tags = {
  Environment = "Development"
  Owner       = "Patrick Moss"
  CostCenter  = "Engineering"
  Tier        = "Landing Zone"
  Project     = "evotaskers"
}
