#!/bin/bash

# Setup Terraform State Storage Account
# This script creates the Azure Storage Account and container for Terraform state files

set -e

# Configuration
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="stterraformstate"
LOCATION="West US 2"
CONTAINER_NAME="tfstate"

echo "🚀 Setting up Terraform State Storage Account..."

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP_NAME"
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --tags Environment=Shared Owner="Patrick Moss" Purpose="Terraform State"

# Create storage account
echo "💾 Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags Environment=Shared Owner="Patrick Moss" Purpose="Terraform State"

# Create container
echo "📁 Creating container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --public-access off

# Enable versioning
echo "🔄 Enabling versioning for state file protection"
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --enable-versioning true

# Enable soft delete
echo "🗑️ Enabling soft delete for additional protection"
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --enable-delete-retention true \
  --delete-retention-days 30

echo "✅ Terraform state storage setup complete!"
echo ""
echo "📋 Configuration Summary:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
echo ""
echo "🔧 Next Steps:"
echo "  1. Update global/backend.tf with these values"
echo "  2. Run 'terraform init' in the global directory"
echo "  3. Deploy the landing zone with 'terraform apply'"
echo ""
echo "🔒 Security Features Enabled:"
echo "  ✅ HTTPS only"
echo "  ✅ TLS 1.2 minimum"
echo "  ✅ No public blob access"
echo "  ✅ Versioning enabled"
echo "  ✅ Soft delete enabled (30 days)"
