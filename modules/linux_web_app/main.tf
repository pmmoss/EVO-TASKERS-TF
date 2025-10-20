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

module "naming_app" {
  source         = "../naming"
  resource_type  = "app"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}

module "naming_pe" {
  source         = "../naming"
  resource_type  = "pe"
  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
}
# App Service Plan for Linux (separate from Function App plan)
resource "azurerm_service_plan" "this" {
  count               = var.create_service_plan ? 1 : 0
  name                = "${module.naming_asp.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  
  # Zone redundancy for high availability (Premium SKUs only)
  zone_balancing_enabled = var.zone_redundant
  
  # Per-app scaling
  per_site_scaling_enabled = var.per_site_scaling_enabled
  
  # Worker count
  worker_count = var.worker_count
  
  tags = merge(var.tags, {
    Application = var.app_name
  })
}

# Auto-scaling settings for the App Service Plan
resource "azurerm_monitor_autoscale_setting" "this" {
  count               = var.enable_autoscale && var.create_service_plan ? 1 : 0
  name                = "autoscale-${module.naming_asp.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_service_plan.this[0].id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = var.autoscale_default_capacity
      minimum = var.autoscale_min_capacity
      maximum = var.autoscale_max_capacity
    }

    # Scale up when CPU > 70%
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this[0].id
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

    # Scale down when CPU < 30%
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this[0].id
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

    # Scale up when Memory > 80%
    rule {
      metric_trigger {
        metric_name        = "MemoryPercentage"
        metric_resource_id = azurerm_service_plan.this[0].id
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

# Linux Web App
resource "azurerm_linux_web_app" "this" {
  name                       = "${module.naming_app.name}-${var.app_name}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = var.create_service_plan ? azurerm_service_plan.this[0].id : var.existing_service_plan_id
  
  # Enable HTTPS only (secure by default)
  https_only = var.https_only
  
  # Client certificate mode
  client_certificate_enabled = var.client_certificate_enabled
  client_certificate_mode    = var.client_certificate_mode
  
  # Disable public network access if private endpoint is enabled
  public_network_access_enabled = var.public_network_access_enabled
  
  # Enable VNet integration for outbound traffic
  virtual_network_subnet_id = var.enable_vnet_integration ? var.subnet_id : null

  # Managed identity - flexible to support SystemAssigned, UserAssigned, or both
  identity {
    type = var.identity_type
    identity_ids = var.identity_type == "SystemAssigned" ? null : (
      var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : 
      var.user_assigned_identity_ids
    )
  }
  
  # Key Vault reference identity
  key_vault_reference_identity_id = var.key_vault_reference_identity_id

  # Application settings
  app_settings = merge(
    var.app_insights_connection_string != null ? {
      # Application Insights
      "APPLICATIONINSIGHTS_CONNECTION_STRING"        = var.app_insights_connection_string
      "ApplicationInsightsAgent_EXTENSION_VERSION"   = "~3"
    } : {},
    var.identity_type != "SystemAssigned" && length(var.user_assigned_identity_ids) > 0 ? {
      # Managed Identity
      "AZURE_CLIENT_ID" = var.user_assigned_identity_client_id
    } : {},
    var.key_vault_uri != null ? {
      # Key Vault reference for secrets (use managed identity)
      "KeyVaultUri" = var.key_vault_uri
    } : {},
    {
      # App settings
      "WEBSITE_RUN_FROM_PACKAGE"         = var.run_from_package
      "WEBSITE_ENABLE_SYNC_UPDATE_SITE"  = var.enable_sync_update_site
    },
    var.additional_app_settings
  )
  
  # Connection strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
  
  # Sticky settings (slot-specific settings)
  # dynamic "sticky_settings" {
  #   for_each = length(var.sticky_app_setting_names) > 0 || length(var.sticky_connection_string_names) > 0 ? [1] : []
  #   content {
  #     app_setting_names       = var.sticky_app_setting_names
  #     connection_string_names = var.sticky_connection_string_names
  #   }
  # }

  site_config {
    # Minimum TLS version
    minimum_tls_version = var.minimum_tls_version
    
    # Always on
    always_on = var.always_on
    
    # FTPs state - disable FTP, allow FTPS only
    ftps_state = var.ftps_state
    
    # HTTP2 enabled
    http2_enabled = var.http2_enabled
    
    # WebSockets
    websockets_enabled = var.websockets_enabled
    
    # Use 32-bit worker process (set to false for production workloads)
    use_32_bit_worker = var.use_32_bit_worker
    
    # Managed pipeline mode
    managed_pipeline_mode = var.managed_pipeline_mode
    
    # Remote debugging
    remote_debugging_enabled = var.remote_debugging_enabled
    remote_debugging_version = var.remote_debugging_enabled ? var.remote_debugging_version : null
    
    # Local MySQL
    local_mysql_enabled = var.local_mysql_enabled
    
    # Container registry settings
    container_registry_use_managed_identity       = var.container_registry_use_managed_identity
    container_registry_managed_identity_client_id = var.container_registry_managed_identity_client_id
    
    # Default documents
    default_documents = var.default_documents
    
    # CORS settings (only enabled if origins are specified)
    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }
    
    # IP restrictions for inbound traffic
    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.value.name
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        priority                  = lookup(ip_restriction.value, "priority", 65000)
        action                    = lookup(ip_restriction.value, "action", "Allow")
        headers = lookup(ip_restriction.value, "headers", null) != null ? [
          {
            x_forwarded_host = lookup(lookup(ip_restriction.value, "headers", {}), "x_forwarded_host", null)
            x_forwarded_for  = lookup(lookup(ip_restriction.value, "headers", {}), "x_forwarded_for", null)
            x_azure_fdid     = lookup(lookup(ip_restriction.value, "headers", {}), "x_azure_fdid", null)
            x_fd_health_probe = lookup(lookup(ip_restriction.value, "headers", {}), "x_fd_health_probe", null)
          }
        ] : []
      }
    }
    
    # SCM IP restrictions
    dynamic "scm_ip_restriction" {
      for_each = var.scm_ip_restrictions
      content {
        name                      = scm_ip_restriction.value.name
        ip_address                = lookup(scm_ip_restriction.value, "ip_address", null)
        service_tag               = lookup(scm_ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(scm_ip_restriction.value, "virtual_network_subnet_id", null)
        priority                  = lookup(scm_ip_restriction.value, "priority", 65000)
        action                    = lookup(scm_ip_restriction.value, "action", "Allow")
      }
    }
    
    scm_use_main_ip_restriction = var.scm_use_main_ip_restriction
    
    # Runtime stack - conditionally set based on var.runtime_stack
    application_stack {
      dotnet_version      = var.runtime_stack == "dotnet" ? var.dotnet_version : null
      node_version        = var.runtime_stack == "node" ? var.node_version : null
      python_version      = var.runtime_stack == "python" ? var.python_version : null
      java_server         = var.runtime_stack == "java" ? var.java_server : null
      java_version        = var.runtime_stack == "java" ? var.java_version : null
      java_server_version = var.runtime_stack == "java" ? var.java_server_version : null
      ruby_version        = var.runtime_stack == "ruby" ? var.ruby_version : null
      php_version         = var.runtime_stack == "php" ? var.php_version : null
      go_version          = var.runtime_stack == "go" ? var.go_version : null
      docker_image_name   = var.runtime_stack == "docker" ? var.docker_image_name : null
      docker_registry_url = var.runtime_stack == "docker" ? var.docker_registry_url : null
      docker_registry_username = var.runtime_stack == "docker" ? var.docker_registry_username : null
      docker_registry_password = var.runtime_stack == "docker" ? var.docker_registry_password : null
    }
    
    # Health check path
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_eviction_time
    
    # Worker count
    worker_count = var.app_worker_count
    
    # Load balancing mode
    load_balancing_mode = var.load_balancing_mode
    
    # Auto heal
    dynamic "auto_heal_setting" {
      for_each = var.enable_auto_heal ? [1] : []
      content {
        action {
          action_type = var.auto_heal_action_type
          minimum_process_execution_time = var.auto_heal_minimum_process_execution_time
        }
        trigger {
          requests {
            count    = var.auto_heal_trigger_requests_count
            interval = var.auto_heal_trigger_requests_interval
          }
          dynamic "slow_request" {
            for_each = var.auto_heal_trigger_slow_request != null ? [var.auto_heal_trigger_slow_request] : []
            content {
              count      = slow_request.value.count
              interval   = slow_request.value.interval
              time_taken = slow_request.value.time_taken
            }
          }
          dynamic "status_code" {
            for_each = var.auto_heal_trigger_status_codes
            content {
              count             = status_code.value.count
              interval          = status_code.value.interval
              status_code_range = status_code.value.status_code_range
              sub_status        = lookup(status_code.value, "sub_status", null)
              win32_status_code = lookup(status_code.value, "win32_status_code", null)
            }
          }
        }
      }
    }
  }

  # Authentication
  dynamic "auth_settings_v2" {
    for_each = var.enable_auth ? [1] : []
    content {
      auth_enabled           = true
      require_authentication = var.auth_require_authentication
      unauthenticated_action = var.auth_unauthenticated_action
      default_provider       = var.auth_default_provider
      runtime_version        = var.auth_runtime_version
      
      dynamic "login" {
        for_each = var.auth_login_enabled ? [1] : []
        content {
          token_store_enabled = var.auth_token_store_enabled
          token_refresh_extension_time = var.auth_token_refresh_extension_hours
          preserve_url_fragments_for_logins = var.auth_preserve_url_fragments
        }
      }
      
      dynamic "active_directory_v2" {
        for_each = var.auth_active_directory_enabled ? [1] : []
        content {
          client_id                  = var.auth_aad_client_id
          tenant_auth_endpoint       = var.auth_aad_tenant_auth_endpoint
          client_secret_setting_name = var.auth_aad_client_secret_setting_name
          allowed_audiences          = var.auth_aad_allowed_audiences
        }
      }
    }
  }
  
  # Storage account mounts
  dynamic "storage_account" {
    for_each = var.storage_accounts
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      share_name   = storage_account.value.share_name
      access_key   = storage_account.value.access_key
      mount_path   = storage_account.value.mount_path
    }
  }
  
  # Backup configuration
  dynamic "backup" {
    for_each = var.enable_backup ? [1] : []
    content {
      name                = "backup-${var.app_name}"
      storage_account_url = var.backup_storage_account_url
      enabled             = true
      
      schedule {
        frequency_interval       = var.backup_frequency_interval
        frequency_unit          = var.backup_frequency_unit
        keep_at_least_one_backup = var.backup_keep_at_least_one
        retention_period_days    = var.backup_retention_period_days
        start_time              = var.backup_start_time
      }
    }
  }
  
  # Logs
  dynamic "logs" {
    for_each = var.enable_detailed_logs ? [1] : []
    content {
      detailed_error_messages = var.logs_detailed_error_messages
      failed_request_tracing  = var.logs_failed_request_tracing
      
      dynamic "application_logs" {
        for_each = var.logs_application_logs_enabled ? [1] : []
        content {
          file_system_level = var.logs_application_logs_file_system_level
        }
      }
      
      dynamic "http_logs" {
        for_each = var.logs_http_logs_enabled ? [1] : []
        content {
          dynamic "file_system" {
            for_each = var.logs_http_logs_file_system_enabled ? [1] : []
            content {
              retention_in_days = var.logs_http_logs_retention_days
              retention_in_mb   = var.logs_http_logs_retention_mb
            }
          }
        }
      }
    }
  }

  tags = var.tags
  
  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

# Deployment Slot (optional, useful for staging)
resource "azurerm_linux_web_app_slot" "staging" {
  count          = var.create_staging_slot ? 1 : 0
  name           = var.staging_slot_name
  app_service_id = azurerm_linux_web_app.this.id
  
  https_only = var.https_only
  
  public_network_access_enabled = var.public_network_access_enabled
  
  virtual_network_subnet_id = var.enable_vnet_integration ? var.subnet_id : null
  
  identity {
    type = var.identity_type
    identity_ids = var.identity_type == "SystemAssigned" ? null : (
      var.identity_type == "SystemAssigned, UserAssigned" ? var.user_assigned_identity_ids : 
      var.user_assigned_identity_ids
    )
  }
  
  app_settings = var.staging_slot_app_settings != null ? var.staging_slot_app_settings : azurerm_linux_web_app.this.app_settings
  
  site_config {
    minimum_tls_version   = var.minimum_tls_version
    always_on             = var.always_on
    ftps_state            = var.ftps_state
    http2_enabled         = var.http2_enabled
    websockets_enabled    = var.websockets_enabled
    use_32_bit_worker     = var.use_32_bit_worker
    health_check_path     = var.health_check_path
    
    application_stack {
      dotnet_version      = var.runtime_stack == "dotnet" ? var.dotnet_version : null
      node_version        = var.runtime_stack == "node" ? var.node_version : null
      python_version      = var.runtime_stack == "python" ? var.python_version : null
      java_server         = var.runtime_stack == "java" ? var.java_server : null
      java_version        = var.runtime_stack == "java" ? var.java_version : null
      java_server_version = var.runtime_stack == "java" ? var.java_server_version : null
      ruby_version        = var.runtime_stack == "ruby" ? var.ruby_version : null
      php_version         = var.runtime_stack == "php" ? var.php_version : null
      go_version          = var.runtime_stack == "go" ? var.go_version : null
      docker_image_name   = var.runtime_stack == "docker" ? var.docker_image_name : null
      docker_registry_url = var.runtime_stack == "docker" ? var.docker_registry_url : null
    }
  }
  
  tags = var.tags
}

# Custom domain binding (optional)
resource "azurerm_app_service_custom_hostname_binding" "this" {
  count               = length(var.custom_domains)
  hostname            = var.custom_domains[count.index].hostname
  app_service_name    = azurerm_linux_web_app.this.name
  resource_group_name = var.resource_group_name
}

# Certificate binding (optional)
resource "azurerm_app_service_certificate_binding" "this" {
  count               = length(var.custom_domains)
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[count.index].id
  certificate_id      = var.custom_domains[count.index].certificate_id
  ssl_state           = var.custom_domains[count.index].ssl_state
}

# Private Endpoint for App Service (optional, recommended for production)
resource "azurerm_private_endpoint" "app_service" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${module.naming_pe.name}-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${module.naming_app.name}-${var.app_name}"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  tags = var.tags
}

# # Diagnostic Settings (if enabled)
# resource "azurerm_monitor_diagnostic_setting" "app_service" {
#   count                      = var.enable_diagnostics ? 1 : 0
#   name                       = "diag-${module.naming_app.name}-${var.app_name}"
#   target_resource_id         = azurerm_linux_web_app.this.id
#   log_analytics_workspace_id = var.log_analytics_workspace_id
#   storage_account_id         = var.diagnostics_storage_account_id
#   eventhub_name              = var.diagnostics_eventhub_name
#   eventhub_authorization_rule_id = var.diagnostics_eventhub_authorization_rule_id

#   # HTTP Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceHTTPLogs") ? [1] : []
#     content {
#       category = "AppServiceHTTPLogs"
#     }
#   }

#   # Console Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceConsoleLogs") ? [1] : []
#     content {
#       category = "AppServiceConsoleLogs"
#     }
#   }

#   # Application Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceAppLogs") ? [1] : []
#     content {
#       category = "AppServiceAppLogs"
#     }
#   }

#   # Audit Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceAuditLogs") ? [1] : []
#     content {
#       category = "AppServiceAuditLogs"
#     }
#   }
  
#   # File Audit Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceFileAuditLogs") ? [1] : []
#     content {
#       category = "AppServiceFileAuditLogs"
#     }
#   }
  
#   # Platform Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServicePlatformLogs") ? [1] : []
#     content {
#       category = "AppServicePlatformLogs"
#     }
#   }
  
#   # IP Security Audit Logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceIPSecAuditLogs") ? [1] : []
#     content {
#       category = "AppServiceIPSecAuditLogs"
#     }
#   }
  
#   # Anti-virus scan logs
#   dynamic "enabled_log" {
#     for_each = contains(var.diagnostic_log_categories, "AppServiceAntivirusScanAuditLogs") ? [1] : []
#     content {
#       category = "AppServiceAntivirusScanAuditLogs"
#     }
#   }

#   enabled_metric {
#     category = "AllMetrics"
#   }
# }

# # Alert rules (optional)
# resource "azurerm_monitor_metric_alert" "cpu_alert" {
#   count               = var.enable_alerts ? 1 : 0
#   name                = "alert-cpu-${module.naming_app.name}-${var.app_name}"
#   resource_group_name = var.resource_group_name
#   scopes              = [var.create_service_plan ? azurerm_service_plan.this[0].id : var.existing_service_plan_id]
#   description         = "Alert when CPU percentage exceeds threshold"
#   severity            = 2
#   frequency           = "PT5M"
#   window_size         = "PT15M"

#   criteria {
#     metric_namespace = "Microsoft.Web/serverfarms"
#     metric_name      = "CpuPercentage"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = var.alert_cpu_threshold
#   }

#   action {
#     action_group_id = var.alert_action_group_id
#   }

#   tags = var.tags
# }

# resource "azurerm_monitor_metric_alert" "memory_alert" {
#   count               = var.enable_alerts ? 1 : 0
#   name                = "alert-memory-${module.naming_app.name}-${var.app_name}"
#   resource_group_name = var.resource_group_name
#   scopes              = [var.create_service_plan ? azurerm_service_plan.this[0].id : var.existing_service_plan_id]
#   description         = "Alert when memory percentage exceeds threshold"
#   severity            = 2
#   frequency           = "PT5M"
#   window_size         = "PT15M"

#   criteria {
#     metric_namespace = "Microsoft.Web/serverfarms"
#     metric_name      = "MemoryPercentage"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = var.alert_memory_threshold
#   }

#   action {
#     action_group_id = var.alert_action_group_id
#   }

#   tags = var.tags
# }

# resource "azurerm_monitor_metric_alert" "response_time_alert" {
#   count               = var.enable_alerts ? 1 : 0
#   name                = "alert-response-${module.naming_app.name}-${var.app_name}"
#   resource_group_name = var.resource_group_name
#   scopes              = [azurerm_linux_web_app.this.id]
#   description         = "Alert when response time exceeds threshold"
#   severity            = 3
#   frequency           = "PT5M"
#   window_size         = "PT15M"

#   criteria {
#     metric_namespace = "Microsoft.Web/sites"
#     metric_name      = "HttpResponseTime"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = var.alert_response_time_threshold
#   }

#   action {
#     action_group_id = var.alert_action_group_id
#   }

#   tags = var.tags
# }

# resource "azurerm_monitor_metric_alert" "http_errors_alert" {
#   count               = var.enable_alerts ? 1 : 0
#   name                = "alert-http-errors-${module.naming_app.name}-${var.app_name}"
#   resource_group_name = var.resource_group_name
#   scopes              = [azurerm_linux_web_app.this.id]
#   description         = "Alert when HTTP 5xx errors exceed threshold"
#   severity            = 1
#   frequency           = "PT5M"
#   window_size         = "PT15M"

#   criteria {
#     metric_namespace = "Microsoft.Web/sites"
#     metric_name      = "Http5xx"
#     aggregation      = "Total"
#     operator         = "GreaterThan"
#     threshold        = var.alert_http_errors_threshold
#   }

#   action {
#     action_group_id = var.alert_action_group_id
#   }

#   tags = var.tags
# }
