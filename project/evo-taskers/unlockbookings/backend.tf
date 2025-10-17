# Backend configuration for UnlockBookings
# Backend values provided by pipeline via -backend-config

terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {}
  
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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}
