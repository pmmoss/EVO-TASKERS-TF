# Backend configuration for AutomatedDataFeed (all environments)
# Workspaces automatically create separate state files with :env suffix

terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {
    resource_group_name  = "rg-evotaskers-state-pmoss"
    storage_account_name = "stevotaskersstatepoc"
    container_name       = "tfstate"
    # Workspace 'dev' will use: landing-zone/evo-taskers-automateddatafeed.tfstateenv:dev
    # Workspace 'qa' will use:  landing-zone/evo-taskers-automateddatafeed.tfstateenv:qa
    # Workspace 'prod' will use: landing-zone/evo-taskers-automateddatafeed.tfstateenv:prod
    key                  = "landing-zone/evo-taskers-automateddatafeed.tfstate"
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
  subscription_id = "b2c30590-db17-4740-b3c6-6853aab1d9a2"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}

