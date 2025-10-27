# ==============================================================================
# EVO-TASKERS COMMON INFRASTRUCTURE - PRODUCTION
# ==============================================================================
# This file contains the core infrastructure values for the landing zone
# Using Azure Verified Modules (AVM) for secure-by-default configurations

# ==============================================================================
# BASIC CONFIGURATION
# ==============================================================================
project     = "pmoss-evotaskers"
environment = "prod"
location    = "West US 2"
location_short = "wus2"

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================
vnet_address_space = ["10.3.0.0/16"]
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
enable_key_vault_access_policy = false # Disable access policies in production, use RBAC only

# Bastion Configuration
enable_bastion = true

# ==============================================================================
# SERVICE PLAN CONFIGURATION
# ==============================================================================
# Function App Service Plan (Windows)
function_app_service_plan_name = "functions-windows"
function_app_service_plan_sku  = "EP2"  # Elastic Premium tier 2 for production
function_app_service_plan_existing_service_plan_id = null

# Logic App Service Plan (Windows)
logic_app_service_plan_name = "logicapps"
logic_app_service_plan_sku  = "WS2"  # Workflow Standard tier 2 for production
logic_app_service_plan_existing_service_plan_id = null

# ==============================================================================
# TAGS
# ==============================================================================
tags = {
  Environment = "Production"
  Owner       = "Patrick Moss"
  CostCenter  = "Engineering"
  Tier        = "Landing Zone"
  Project     = "evotaskers"
  ManagedBy   = "Terraform"
  CreatedBy   = "Patrick Moss"
  Criticality = "High"
  Compliance  = "Required"
}
