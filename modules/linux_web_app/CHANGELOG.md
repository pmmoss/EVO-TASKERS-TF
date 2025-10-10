# Changelog

All notable changes to the Linux Web App module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-10-10

### Added - Major Enhancements

#### High Availability & Scalability
- **Autoscaling Support**: Automatic scaling based on CPU and memory metrics
- **Zone Redundancy**: Multi-zone deployment support for Premium SKUs
- **Worker Count Configuration**: Flexible worker configuration
- **Per-Site Scaling**: Option to enable per-site scaling on App Service Plans
- **Load Balancing Modes**: Multiple load balancing strategies (LeastRequests, LeastResponseTime, etc.)

#### Security Enhancements
- **Flexible Identity Management**: Support for SystemAssigned, UserAssigned, or hybrid identities
- **Client Certificate Authentication**: Optional mutual TLS support
- **IP Restrictions**: Granular IP-based access controls with header filtering
- **SCM IP Restrictions**: Separate access controls for Kudu/SCM site
- **Azure AD Authentication**: Built-in authentication with Azure Active Directory v2
- **Public Network Access Control**: Configurable public access

#### Networking Features
- **Existing Service Plan Support**: Option to use existing App Service Plan
- **Custom Domains**: Support for custom domain bindings with SSL certificates
- **Enhanced Private Endpoint**: Improved private endpoint configuration with DNS
- **VNet Integration Control**: More flexible VNet integration options

#### Monitoring & Observability
- **Comprehensive Diagnostics**: 8 log categories including Platform and IP Security logs
- **Multiple Destinations**: Support for Log Analytics, Storage Account, and Event Hub
- **Metric Alerts**: Built-in alerts for CPU, memory, response time, and HTTP errors
- **Action Group Integration**: Easy integration with Azure Monitor Action Groups
- **Enhanced Health Checks**: Configurable health check paths and eviction times

#### Reliability & Recovery
- **Auto-Heal Configuration**: Automatic recovery from failures with customizable triggers
  - Request count triggers
  - Slow request triggers
  - Status code triggers
- **Backup & Restore**: Automated backup configuration with flexible scheduling
- **Deployment Slots**: Staging slot support for blue-green deployments
- **Sticky Settings**: Slot-specific settings support

#### Development & Operations
- **Additional Runtime Stacks**: Added Ruby, PHP, Go support
- **Docker Support**: Enhanced container deployment with managed identity for ACR
- **Storage Account Mounting**: Support for mounting Azure Storage as volumes
- **Connection Strings**: Secure connection string management with Key Vault integration
- **Remote Debugging**: VS2022 remote debugging support
- **Detailed Logging**: Comprehensive application and HTTP logging configuration
- **WebSockets Support**: Configurable WebSocket support
- **Default Documents**: Custom default document configuration

#### Configuration Flexibility
- **Lifecycle Management**: Customizable lifecycle ignore_changes rules
- **Managed Pipeline Mode**: Integrated or Classic pipeline options
- **Container Registry Settings**: Managed identity support for container registries
- **CORS Credentials**: Support for credentials in CORS requests
- **TLS Version Control**: Configurable minimum TLS version
- **FTPS State Control**: Granular FTP/FTPS configuration

### Changed - Breaking Changes

- **Identity Configuration**: `identity_type` variable replaces separate boolean flags
  - Old: `use_system_assigned_identity` (boolean)
  - New: `identity_type` (string: "SystemAssigned", "UserAssigned", or "SystemAssigned, UserAssigned")
- **Identity IDs**: Changed from singular to plural list
  - Old: `user_assigned_identity_id` (string)
  - New: `user_assigned_identity_ids` (list)
- **Service Plan**: Made service plan creation optional
  - New: `create_service_plan` (boolean, default: true)
  - New: `existing_service_plan_id` (string, for using existing plans)
- **Resource References**: Service plan ID now uses conditional logic
  - Affects: `azurerm_service_plan.this.id` → `azurerm_service_plan.this[0].id`
- **Public Network Access**: Changed from computed to explicit variable
  - Old: Automatically disabled when private endpoint enabled
  - New: `public_network_access_enabled` explicit variable (default: true)
- **Diagnostic Metrics**: Updated from deprecated `metric` to `enabled_metric` block
- **HTTPS Configuration**: Made configurable instead of hardcoded
  - New: `https_only` variable (default: true)
- **App Settings**: Made Application Insights optional
  - Old: Always included App Insights settings
  - New: Conditionally added if connection string provided
- **Key Vault URI**: Made optional
  - Old: Required variable
  - New: Optional, conditionally added to app settings

### Changed - Non-Breaking

- **Outputs**: Enhanced with comprehensive app service details object
- **Worker Count**: Added to both service plan and site config
- **Diagnostic Categories**: Made configurable via list variable
- **App Settings Structure**: Improved conditional merging logic
- **Tags**: More consistent tag application across resources

### Added - New Variables

#### Service Plan (6 new)
- `create_service_plan`
- `existing_service_plan_id`
- `zone_redundant`
- `per_site_scaling_enabled`
- `worker_count`

#### Autoscaling (7 new)
- `enable_autoscale`
- `autoscale_default_capacity`
- `autoscale_min_capacity`
- `autoscale_max_capacity`
- `autoscale_cpu_threshold_up`
- `autoscale_cpu_threshold_down`
- `autoscale_memory_threshold_up`

#### Identity (2 changed + 1 new)
- `identity_type` (replaces old approach)
- `user_assigned_identity_ids` (replaces singular)
- `key_vault_reference_identity_id` (new)

#### Security (5 new)
- `client_certificate_enabled`
- `client_certificate_mode`
- `https_only`
- `public_network_access_enabled`
- `minimum_tls_version` (now configurable)

#### Networking (2 new)
- `ip_restrictions` (list of objects)
- `scm_ip_restrictions` (list of objects)
- `scm_use_main_ip_restriction`

#### Runtime (9 new)
- `ruby_version`
- `php_version`
- `go_version`
- `docker_image_name`
- `docker_registry_url`
- `docker_registry_username`
- `docker_registry_password`

#### Site Config (15 new)
- `ftps_state` (now configurable)
- `websockets_enabled`
- `managed_pipeline_mode`
- `remote_debugging_enabled`
- `remote_debugging_version`
- `local_mysql_enabled`
- `container_registry_use_managed_identity`
- `container_registry_managed_identity_client_id`
- `default_documents`
- `app_worker_count`
- `load_balancing_mode`
- `cors_support_credentials`
- `http2_enabled` (now configurable)
- `use_32_bit_worker` (now configurable)

#### Auto-Heal (6 new)
- `enable_auto_heal`
- `auto_heal_action_type`
- `auto_heal_minimum_process_execution_time`
- `auto_heal_trigger_requests_count`
- `auto_heal_trigger_requests_interval`
- `auto_heal_trigger_slow_request`
- `auto_heal_trigger_status_codes`

#### App Settings (4 new)
- `run_from_package` (now configurable)
- `enable_sync_update_site` (now configurable)
- `connection_strings`
- `sticky_app_setting_names`
- `sticky_connection_string_names`

#### Authentication (13 new)
- `enable_auth`
- `auth_require_authentication`
- `auth_unauthenticated_action`
- `auth_default_provider`
- `auth_runtime_version`
- `auth_login_enabled`
- `auth_token_store_enabled`
- `auth_token_refresh_extension_hours`
- `auth_preserve_url_fragments`
- `auth_active_directory_enabled`
- `auth_aad_client_id`
- `auth_aad_tenant_auth_endpoint`
- `auth_aad_client_secret_setting_name`
- `auth_aad_allowed_audiences`

#### Storage & Backup (8 new)
- `storage_accounts`
- `enable_backup`
- `backup_storage_account_url`
- `backup_frequency_interval`
- `backup_frequency_unit`
- `backup_keep_at_least_one`
- `backup_retention_period_days`
- `backup_start_time`

#### Logging (8 new)
- `enable_detailed_logs`
- `logs_detailed_error_messages`
- `logs_failed_request_tracing`
- `logs_application_logs_enabled`
- `logs_application_logs_file_system_level`
- `logs_http_logs_enabled`
- `logs_http_logs_file_system_enabled`
- `logs_http_logs_retention_days`
- `logs_http_logs_retention_mb`

#### Deployment Slots (3 new)
- `create_staging_slot`
- `staging_slot_name`
- `staging_slot_app_settings`

#### Custom Domains (1 new)
- `custom_domains`

#### Diagnostics (5 new)
- `diagnostics_storage_account_id`
- `diagnostics_eventhub_name`
- `diagnostics_eventhub_authorization_rule_id`
- `diagnostic_log_categories`
- `diagnostic_metrics_enabled`

#### Alerts (5 new)
- `enable_alerts`
- `alert_action_group_id`
- `alert_cpu_threshold`
- `alert_memory_threshold`
- `alert_response_time_threshold`
- `alert_http_errors_threshold`

#### Lifecycle (1 new)
- `lifecycle_ignore_changes`

**Total New Variables: ~105**
**Total Variables in v2.0: ~145**

### Added - New Outputs

- `app_service_default_site_hostname` - Full HTTPS URL
- `app_service_outbound_ip_addresses` - Outbound IP list
- `app_service_possible_outbound_ip_addresses` - Possible outbound IPs
- `app_service_kind` - App kind
- `app_service_custom_domain_verification_id` - Custom domain verification
- `app_service_identity_tenant_id` - Identity tenant ID
- `app_service_identity_type` - Identity type
- `app_service_identity_identity_ids` - User-assigned identity IDs
- `service_plan_kind` - Service plan kind
- `service_plan_reserved` - Service plan reserved status
- `private_endpoint_network_interface_id` - PE network interface
- `vnet_integration_subnet_id` - VNet integration subnet
- `staging_slot_id` - Staging slot ID
- `staging_slot_name` - Staging slot name
- `staging_slot_default_hostname` - Staging slot hostname
- `custom_domain_bindings` - Custom domain details
- `diagnostic_setting_id` - Diagnostic setting ID
- `autoscale_setting_id` - Autoscale setting ID
- `cpu_alert_id` - CPU alert ID
- `memory_alert_id` - Memory alert ID
- `response_time_alert_id` - Response time alert ID
- `http_errors_alert_id` - HTTP errors alert ID
- `site_config` - Site configuration summary
- `app_service_details` - Comprehensive details object

### Added - New Resources

- `azurerm_monitor_autoscale_setting` - Autoscaling configuration
- `azurerm_linux_web_app_slot` - Deployment slot
- `azurerm_app_service_custom_hostname_binding` - Custom domains
- `azurerm_app_service_certificate_binding` - SSL certificates
- `azurerm_monitor_metric_alert` (4 types) - Monitoring alerts

### Added - Documentation

- **EXAMPLES.md**: 8 comprehensive usage examples
- **CHANGELOG.md**: This file
- **MIGRATION.md**: Guide for upgrading from v1.0
- **Enhanced README.md**: Complete documentation with all features

### Improved

- **Validation Rules**: Added validation for several variables
- **Error Handling**: Better error messages for invalid configurations
- **Code Organization**: Better structured with clear sections
- **Comments**: Improved inline documentation
- **Examples**: Real-world production examples

### Security

- **Default Secure**: More secure defaults (HTTPS only, TLS 1.2, FTP disabled)
- **Least Privilege**: Better support for managed identity
- **Secret Management**: Enhanced Key Vault integration
- **Network Isolation**: Better private networking support

### Performance

- **Autoscaling**: Automatic performance optimization
- **Zone Redundancy**: High availability support
- **Always On**: Configurable warm-up settings
- **Load Balancing**: Multiple strategies for optimization

### Fixed

- Deprecation warning for `metric` block (now uses `enabled_metric`)
- Conditional resource creation properly uses count
- Output references updated for conditional resources

### Deprecated

None. This is a major version with breaking changes.

### Removed

- Hardcoded assumptions about identity configuration
- Forced App Insights configuration
- Automatic public network access logic

---

## [1.0.0] - Initial Release

### Added
- Basic Linux Web App provisioning
- Service Plan creation
- User-assigned identity support
- VNet integration
- Private endpoint (optional)
- Basic diagnostic settings
- Application Insights integration
- Key Vault URI configuration
- Health checks
- CORS support
- Multiple runtime stacks (dotnet, node, python, java)
- Basic outputs

### Security
- HTTPS only (forced)
- TLS 1.2 minimum (forced)
- FTP disabled (forced)

---

## Migration Notes

See [MIGRATION.md](./MIGRATION.md) for detailed upgrade instructions from v1.0 to v2.0.

## Compatibility

- **Terraform**: >= 1.0
- **AzureRM Provider**: ~> 4.0
- **Azure API**: Latest stable

## Support

For issues, questions, or contributions, please contact the platform engineering team.

