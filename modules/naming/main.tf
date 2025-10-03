# Naming convention module
# Output: <type>-<project>-<env>-<location>

locals {
  # Standard naming pattern
  name = lower(join("-", [var.resource_type, var.project, var.environment, var.location_short]))
  
  # Azure Storage Account naming (no hyphens, lowercase, 3-24 chars)
  storage_name = lower(replace(join("", [var.resource_type, var.project, var.environment, var.location_short]), "-", ""))
  
  # Azure Key Vault naming (no hyphens, 3-24 chars, alphanumeric only)
  keyvault_name = lower(replace(join("", [var.resource_type, var.project, var.environment, var.location_short]), "-", ""))
  
  # Generic Azure resource naming (no hyphens for most Azure resources)
  azure_name = lower(replace(join("", [var.resource_type, var.project, var.environment, var.location_short]), "-", ""))
}

