module "app_service" {
  source = "../../../modules/app_service"
  project = "pmoss-evotaskers"
  environment = "dev"
  location = "West US 2"
  location_short = "wus2"
  resource_group_name = module.landing_zone.resource_group_name
  log_analytics_workspace_id = module.landing_zone.log_analytics_workspace_id
  subnet_id = module.landing_zone.subnet_id
  admin_object_ids = module.landing_zone.admin_object_ids
  reader_object_ids = module.landing_zone.reader_object_ids
  enable_diagnostics = module.landing_zone.enable_diagnostics
  tags = module.landing_zone.tags
  app_service_os_type = "Linux"
  app_service_sku = "B1"
  app_service_always_on = false
  app_service_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
  }
}