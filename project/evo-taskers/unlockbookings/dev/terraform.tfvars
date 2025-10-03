# Dev Environment Variables
# This file contains environment-specific values

# Basic Configuration
project     = "revms"
environment = "dev"
location    = "West US 2"
location_short = "wus2"
# Network Configuration
vnet_address_space = ["10.1.0.0/16"]
hub_firewall_ip    = "" # Set this to your hub firewall IP when available

# Security Configuration
admin_object_ids = [
  # Add your admin object IDs here
  # Example: "00000000-0000-0000-0000-000000000000"
]

reader_object_ids = [
  # Add your reader object IDs here
]

enable_key_vault_access_policy = true # Enable for initial setup
enable_bastion                  = true

# App Service Configuration
app_service_os_type = "Linux"
app_service_sku      = "B1"
app_service_always_on = false # Set to true for production

app_service_settings = {
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
}

# Tags
tags = {
  Environment = "Development"
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
}
