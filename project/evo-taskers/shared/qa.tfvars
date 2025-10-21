# QA Environment Configuration for Shared Services
environment = "qa"

# ==============================================================================
# APP SERVICE PLANS
# ==============================================================================

# Windows Function App Service Plan Configuration
windows_function_plan_sku              = "EP1"  # Elastic Premium for QA
windows_function_plan_enable_autoscale = false  # Can enable if needed
windows_function_plan_min_capacity     = 1
windows_function_plan_max_capacity     = 5

# Logic App Service Plan Configuration
logic_app_plan_sku = "WS1"  # Workflow Standard tier 1

# ==============================================================================
# TAGS
# ==============================================================================

# Additional tags
additional_tags = {
  CostCenter  = "Engineering"
  Environment = "QA"
}


