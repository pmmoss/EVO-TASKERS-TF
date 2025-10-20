# UnlockBookings Application Infrastructure
# This file contains shared configuration for all environments

# Data source to reference common infrastructure (landing zone resources)
data "terraform_remote_state" "common" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "landing-zone/evo-taskers-common-${var.environment}.tfstate"
  }
}

# Data source to reference shared services (App Service Plans, Event Hubs, etc.)
data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "shared/evo-taskers-shared-${var.environment}.tfstate"
  }
}

# Local variables
locals {
  project        = data.terraform_remote_state.common.outputs.project
  environment    = data.terraform_remote_state.common.outputs.environment
  location       = data.terraform_remote_state.common.outputs.location
  location_short = data.terraform_remote_state.common.outputs.location_short
  logic_app_plan_id = data.terraform_remote_state.shared.outputs.logic_app_plan_id
  windows_function_plan_id = data.terraform_remote_state.shared.outputs.windows_function_plan_id
  # data.terraform_remote_state.shared.outputs.event_hub_namespace_id
  # data.terraform_remote_state.shared.outputs.event_hub_id
  # data.terraform_remote_state.shared.outputs.event_hub_consumer_group_id
  # data.terraform_remote_state.shared.outputs.event_hub_consumer_group_name
  # data.terraform_remote_state.shared.outputs.event_hub_consumer_group_id
  # Merge common tags with unlockbookings-specific tags
  tags = merge(
    data.terraform_remote_state.common.outputs.tags,
    {
      Application = "UnlockBookings"
      Component   = "Workflow"
    }
  )
}

