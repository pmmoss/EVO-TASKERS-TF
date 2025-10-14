#!/bin/bash

# Script to Fix Hardcoded Backend Configurations
# This script updates backend.tf files to remove hardcoded subscription IDs
# and prepares them for Azure DevOps pipeline deployment

set -e

echo "🔧 Fixing Backend Configurations..."
echo ""

# Root directory of the Terraform project
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "Project root: $PROJECT_ROOT"
echo ""

# Backup directory
BACKUP_DIR="$PROJECT_ROOT/backend-config/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Creating backups in: $BACKUP_DIR"
echo ""

# Find all backend.tf files
BACKEND_FILES=$(find "$PROJECT_ROOT" -name "backend.tf" -type f | grep -E "(project|global)" || true)

if [ -z "$BACKEND_FILES" ]; then
    echo "❌ No backend.tf files found!"
    exit 1
fi

echo "Found backend.tf files:"
echo "$BACKEND_FILES" | nl
echo ""

read -p "Do you want to proceed with fixing these files? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted by user"
    exit 0
fi

echo ""
echo "🔄 Processing files..."
echo ""

# Counter for files processed
PROCESSED=0

while IFS= read -r BACKEND_FILE; do
    if [ ! -f "$BACKEND_FILE" ]; then
        continue
    fi
    
    echo "Processing: $BACKEND_FILE"
    
    # Create backup
    BACKUP_FILE="$BACKUP_DIR/$(basename $(dirname "$BACKEND_FILE"))-backend.tf.bak"
    cp "$BACKEND_FILE" "$BACKUP_FILE"
    echo "  ✅ Backup created: $BACKUP_FILE"
    
    # Create new backend.tf without hardcoded subscription_id
    cat > "$BACKEND_FILE.tmp" << 'EOF'
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
EOF
    
    # Replace the file
    mv "$BACKEND_FILE.tmp" "$BACKEND_FILE"
    echo "  ✅ Updated: $BACKEND_FILE"
    echo ""
    
    ((PROCESSED++))
done <<< "$BACKEND_FILES"

echo "✅ Processed $PROCESSED backend.tf files"
echo ""
echo "📋 Summary:"
echo "  - Original files backed up to: $BACKUP_DIR"
echo "  - Backend configurations updated to use environment variables"
echo "  - Hardcoded subscription IDs removed"
echo ""
echo "⚠️  IMPORTANT: Next steps:"
echo "1. Review the changes in each backend.tf file"
echo "2. Update your variable groups with correct backend configuration"
echo "3. Test terraform init locally with backend-config:"
echo "   terraform init -backend-config=\"resource_group_name=...\" \\"
echo "                  -backend-config=\"storage_account_name=...\" \\"
echo "                  -backend-config=\"container_name=...\" \\"
echo "                  -backend-config=\"key=...\""
echo "4. Commit the changes to your repository"
echo "5. Run the Azure DevOps pipelines"
echo ""
echo "💾 To restore from backup (if needed):"
echo "   cp $BACKUP_DIR/<file>.bak <original-location>/backend.tf"

