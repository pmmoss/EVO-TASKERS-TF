# Shared App Service Plans for EVO-TASKERS Applications
# These plans are shared across multiple applications to optimize costs and resource utilization

# ==============================================================================
# WINDOWS FUNCTION APP SERVICE PLAN
# ==============================================================================
# Shared by: dashboard, sendgrid, automateddatafeed, autoopenshorex
# This plan hosts multiple Windows-based Function Apps

module "windows_function_plan" {
  source = "../../../modules/app_service_plan"
  
  project             = local.project
  plan_name           = "functions-windows"
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  os_type  = "Windows"
  sku_name = var.windows_function_plan_sku
  
  # Enable autoscaling for production workloads
  enable_autoscale           = var.windows_function_plan_enable_autoscale
  autoscale_min_capacity     = var.windows_function_plan_min_capacity
  autoscale_max_capacity     = var.windows_function_plan_max_capacity
  autoscale_cpu_threshold_up = 70
  autoscale_cpu_threshold_down = 30
  
  plan_purpose = "Shared Windows Function Apps"
  
  tags = merge(
    local.common_tags,
    var.additional_tags,
    {
      Purpose     = "Function Apps Hosting"
      Workload    = "Dashboard, SendGrid, AutomatedDataFeed, AutoOpenShoreX"
      CostCenter  = "Engineering"
    }
  )
}

# ==============================================================================
# LOGIC APP SERVICE PLAN
# ==============================================================================
# Shared by: unlockbookings (and future Logic Apps)
# This plan hosts Logic App Standard workflows

module "logic_app_plan" {
  source = "../../../modules/app_service_plan"
  
  project             = local.project
  plan_name           = "logicapps"
  environment         = local.environment
  location            = local.location
  location_short      = local.location_short
  resource_group_name = data.terraform_remote_state.common.outputs.resource_group_name
  
  os_type  = "Windows"
  sku_name = var.logic_app_plan_sku
  
  # Logic Apps typically don't need autoscaling at the plan level
  # They have their own workflow-level scaling
  enable_autoscale = false
  
  plan_purpose = "Shared Logic Apps Standard"
  
  tags = merge(
    local.common_tags,
    var.additional_tags,
    {
      Purpose     = "Logic Apps Hosting"
      Workload    = "UnlockBookings Workflows"
      CostCenter  = "Engineering"
    }
  )
}

