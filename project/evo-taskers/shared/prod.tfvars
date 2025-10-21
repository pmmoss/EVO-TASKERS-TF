# Production Environment Configuration for Shared Services
environment = "prod"

# ==============================================================================
# APP SERVICE PLANS
# ==============================================================================

# Windows Function App Service Plan Configuration
windows_function_plan_sku              = "EP2"  # Elastic Premium tier 2 for production
windows_function_plan_enable_autoscale = true   # Enable autoscaling in production
windows_function_plan_min_capacity     = 2      # Higher minimum for HA
windows_function_plan_max_capacity     = 10     # Higher maximum for peak loads

# Logic App Service Plan Configuration
logic_app_plan_sku = "WS2"  # Workflow Standard tier 2 for production

# ==============================================================================
# TAGS
# ==============================================================================

# Additional tags
additional_tags = {
  CostCenter  = "Engineering"
  Environment = "Production"
}


