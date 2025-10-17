# Backend configuration for Landing Zone state
# This uses a separate state file from application deployments

terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {
    # resource_group_name  = "rg-evotaskers-state-pmoss"
    # storage_account_name = "stevotaskersstatepoc"
    # container_name       = "tfstate"
    # key                  = "landing-zone/evo-taskers-common-dev.tfstate"
  }
  
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

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}