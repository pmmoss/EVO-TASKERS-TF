# Development Environment Configuration for Shared Services

subscription_id = var.subscription_id
environment     = var.environment

# Windows Function App Service Plan Configuration
windows_function_plan_sku              = "EP1"  # Elastic Premium for dev
windows_function_plan_enable_autoscale = false  # Disable autoscale in dev to save costs
windows_function_plan_min_capacity     = 1
windows_function_plan_max_capacity     = 3

# Logic App Service Plan Configuration
logic_app_plan_sku = "WS1"  # Workflow Standard tier 1

# Additional tags
additional_tags = {
  CostCenter  = "Engineering"
  Environment = "Development"
}

