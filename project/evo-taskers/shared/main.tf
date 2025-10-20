# EVO-TASKERS Shared Services Infrastructure
# This module contains shared services like App Service Plans, Event Hubs, APIM, etc.
# that are used across multiple applications

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

# Local variables derived from common infrastructure
locals {
  project        = data.terraform_remote_state.common.outputs.project
  environment    = data.terraform_remote_state.common.outputs.environment
  location       = data.terraform_remote_state.common.outputs.location
  location_short = data.terraform_remote_state.common.outputs.location_short
  
  # Merge common tags with shared-specific tags
  common_tags = merge(
    data.terraform_remote_state.common.outputs.tags,
    {
      Module      = "Shared Services"
      ManagedBy   = "Terraform"
      StateFile   = "shared/evo-taskers-shared-${var.environment}.tfstate"
    }
  )
}

