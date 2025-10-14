# Backend configuration
# Subscription ID is provided by Azure DevOps service connection via ARM_SUBSCRIPTION_ID
# Backend state configuration is provided via -backend-config in pipeline

terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {
    # Backend configuration provided via pipeline:
    # - resource_group_name
    # - storage_account_name
    # - container_name
    # - key
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
  # subscription_id is set via ARM_SUBSCRIPTION_ID environment variable
  # This is automatically provided by Azure DevOps service connection
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}
