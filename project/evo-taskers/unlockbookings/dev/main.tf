# Data source to reference common infrastructure outputs
data "terraform_remote_state" "common" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    key                  = "landing-zone/evo-taskers-common-dev.tfstate"
  }
}

# Local variables
locals {
  project        = data.terraform_remote_state.common.outputs.project
  environment    = data.terraform_remote_state.common.outputs.environment
  location       = data.terraform_remote_state.common.outputs.location
  location_short = data.terraform_remote_state.common.outputs.location_short
  tags = merge(
    data.terraform_remote_state.common.outputs.tags,
    {
      Application = "UnlockBookings"
      Component   = "API"
    }
  )
}