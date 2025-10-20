# Shared Services Outputs
# These outputs are consumed by individual application modules

# ==============================================================================
# APP SERVICE PLANS
# ==============================================================================

output "windows_function_plan_id" {
  value       = module.windows_function_plan.id
  description = "The ID of the shared Windows Function App Service Plan"
}

output "windows_function_plan_name" {
  value       = module.windows_function_plan.name
  description = "The name of the shared Windows Function App Service Plan"
}

output "windows_function_plan_sku" {
  value       = module.windows_function_plan.sku_name
  description = "The SKU of the shared Windows Function App Service Plan"
}

output "logic_app_plan_id" {
  value       = module.logic_app_plan.id
  description = "The ID of the shared Logic App Service Plan"
}

output "logic_app_plan_name" {
  value       = module.logic_app_plan.name
  description = "The name of the shared Logic App Service Plan"
}

output "logic_app_plan_sku" {
  value       = module.logic_app_plan.sku_name
  description = "The SKU of the shared Logic App Service Plan"
}

# ==============================================================================
# COMMON CONFIGURATION (Pass-through from common state)
# ==============================================================================

output "project" {
  value       = local.project
  description = "Project name"
}

output "environment" {
  value       = local.environment
  description = "Environment name"
}

output "location" {
  value       = local.location
  description = "Azure region"
}

output "location_short" {
  value       = local.location_short
  description = "Short Azure region code"
}

