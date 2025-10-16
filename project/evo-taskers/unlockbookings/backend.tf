# Backend configuration for UnlockBookings Dev Environment
# This uses a separate state file from common infrastructure

terraform {
  required_version = ">=1.2"
  
   backend "azurerm" {
    # ... your existing config
    use_azuread_auth = true  # Keeps backend using OIDC/WIF
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3"
    }
  }
}

provider "azurerm" {
  # Enable OIDC for workload identity federation
  use_oidc = true
  use_cli  = false  # Critical: Disable CLI to force OIDC
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
provider "azuread" {
  use_oidc = true
  use_cli  = false  # If applicable
}

provider "random" {}
