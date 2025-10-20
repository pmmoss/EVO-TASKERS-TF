terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Naming for resources
module "naming_asp" {
  source         = "../naming"
  resource_type  = "asp"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

# App Service Plan
resource "azurerm_service_plan" "this" {
  name                = var.custom_name != null ? var.custom_name : "${module.naming_asp.name}-${var.plan_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  sku_name            = var.sku_name
  
  # Zone redundancy for high availability (Premium SKUs only)
  zone_balancing_enabled = var.zone_redundant
  
  # Per-app scaling
  per_site_scaling_enabled = var.per_site_scaling_enabled
  
  # Worker count
  worker_count = var.worker_count
  
  tags = merge(var.tags, {
    Purpose = var.plan_purpose
  })
}

# Auto-scaling settings for the App Service Plan (optional)
resource "azurerm_monitor_autoscale_setting" "this" {
  count               = var.enable_autoscale ? 1 : 0
  name                = "autoscale-${azurerm_service_plan.this.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_service_plan.this.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = var.autoscale_default_capacity
      minimum = var.autoscale_min_capacity
      maximum = var.autoscale_max_capacity
    }

    # Scale up when CPU > threshold
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale_cpu_threshold_up
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale down when CPU < threshold
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.autoscale_cpu_threshold_down
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }

    # Scale up when Memory > threshold
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale_memory_threshold_up
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}

