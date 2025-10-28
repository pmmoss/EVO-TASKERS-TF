# Backend configuration for common infrastructure
# Using HCP Terraform Cloud backend

terraform {
  required_version = ">=1.13"
  
  cloud {
    organization = ""
    workspaces {
      name = "evo-taskers-common"
    }
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.49"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
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