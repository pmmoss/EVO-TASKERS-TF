# Central definition of resource type abbreviations
# Based on https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations

locals {
  resource_types = {
    # Core Resources
    resource_group          = "rg"
    virtual_network         = "vnet"
    subnet                  = "snet"
    network_security_group  = "nsg"
    route_table             = "route"
    app_insights            = "appi"
    log_analytics_workspace = "log"
    key_vault               = "kv"
    storage_account         = "st"
    application_insights    = "appi"
    user_assigned_identity  = "umi"
    
    # App Services
    app_service_plan        = "asp"
    web_app                 = "app"
    function_app            = "func"
    logic_app               = "logic"
    
    # Optional Resources
    redis_cache             = "redis"
    api_management          = "apim"
    app_gateway             = "agw"
    event_hub               = "evh"
    service_bus             = "sb"
    bastion                 = "bas"
    bastion_host            = "bas"
    public_ip               = "pip"
    
    # Private Endpoints
    private_endpoint        = "pe"
    private_service_connection = "psc"
  }
}

output "resource_types" {
  value       = local.resource_types
  description = "Map of Azure resource types to their standard abbreviations"
}
