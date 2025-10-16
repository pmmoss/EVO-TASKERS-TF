# Backend configuration for UnlockBookings Dev Environment
# This uses a separate state file from common infrastructure

terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {}
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46"
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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}
