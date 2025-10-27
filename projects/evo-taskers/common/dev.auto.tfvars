# ==============================================================================
# EVO-TASKERS COMMON INFRASTRUCTURE - DEVELOPMENT
# ==============================================================================
# This file contains the core infrastructure values for the landing zone
# Using Azure Verified Modules (AVM) for secure-by-default configurations

# ==============================================================================
# BASIC CONFIGURATION
# ==============================================================================
project     = "pmoss-evotaskers"
environment = "dev"
location    = "West US 2"
location_short = "wus2"

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================
vnet_address_space = ["10.1.0.0/16"]
hub_firewall_ip    = "" # Set this to your hub firewall IP when available

# ==============================================================================
# SECURITY CONFIGURATION
# ==============================================================================
# Add your actual Azure AD object IDs here
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

# ==============================================================================
# SERVICE PLAN CONFIGURATION
# ==============================================================================
# Function App Service Plan (Windows)
function_app_service_plan_name = "functions-windows"
function_app_service_plan_sku  = "EP1"  # Elastic Premium for dev
function_app_service_plan_existing_service_plan_id = null

# Logic App Service Plan (Windows)
logic_app_service_plan_name = "logicapps"
logic_app_service_plan_sku  = "WS1"  # Workflow Standard tier 1
logic_app_service_plan_existing_service_plan_id = null

# ==============================================================================
# TAGS
# ==============================================================================

tags = {
  Environment = "Development"
  Owner       = "Patrick Moss"
  CostCenter  = "Engineering"
  Tier        = "Landing Zone"
  Project     = "evotaskers"
  ManagedBy   = "Terraform"
  CreatedBy   = "Patrick Moss"
}
