# Backend configuration for Landing Zone state
# Using HCP Terraform Cloud backend

terraform {
  required_version = ">=1.2"
  
  cloud {
    organization = "your-hcp-organization"
    workspaces {
      name = "evo-taskers-global"
    }
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