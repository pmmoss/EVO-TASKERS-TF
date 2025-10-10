# AutomatedDataFeed Application Infrastructure
# This file contains shared configuration for all environments using workspaces

# Get environment from workspace name
locals {
  # Use workspace name as environment
  environment = terraform.workspace
  
  # Validation: ensure we're using a valid workspace
  valid_workspaces = ["dev", "qa", "prod"]
  workspace_valid  = contains(local.valid_workspaces, terraform.workspace)
}

# Add validation to prevent using default or invalid workspaces
resource "null_resource" "workspace_validation" {
  lifecycle {
    precondition {
      condition     = local.workspace_valid
      error_message = "Workspace must be one of: ${join(", ", local.valid_workspaces)}. Current workspace: ${terraform.workspace}"
    }
  }
}

# Data source to reference common infrastructure outputs
# The environment-specific key is constructed using workspace name
data "terraform_remote_state" "common" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "landing-zone/evo-taskers-common-${local.environment}.tfstate"
  }
}

# Local variables
locals {
  project        = data.terraform_remote_state.common.outputs.project
  location       = data.terraform_remote_state.common.outputs.location
  location_short = data.terraform_remote_state.common.outputs.location_short
  
  tags = merge(
    data.terraform_remote_state.common.outputs.tags,
    {
      Application = "AutomatedDataFeed"
      Component   = "API"
      Workspace   = terraform.workspace
    }
  )
}

