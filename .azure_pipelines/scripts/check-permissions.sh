#!/bin/bash
# Check if you have the necessary permissions to manage federated credentials

set -e

echo "Checking Azure Permissions..."
echo "=============================="
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure"
    echo "Run: az login"
    exit 1
fi

echo "✓ Logged into Azure"
echo ""

# Get current account
ACCOUNT_NAME=$(az account show --query user.name -o tsv)
ACCOUNT_TYPE=$(az account show --query user.type -o tsv)

echo "Current Account:"
echo "  Name: $ACCOUNT_NAME"
echo "  Type: $ACCOUNT_TYPE"
echo ""

# Check for App ID
echo "Enter the Application (Client) ID to test permissions:"
read -p "App ID: " APP_ID

if [ -z "$APP_ID" ]; then
    echo "No App ID provided"
    exit 1
fi

echo ""
echo "Testing permissions..."
echo ""

# Test 1: Can we read the app registration?
echo "1. Testing READ access to app registration..."
if az ad app show --id "$APP_ID" &> /dev/null; then
    echo "   ✓ Can read app registration"
else
    echo "   ❌ Cannot read app registration"
    echo "   You need 'Application Administrator' or 'Cloud Application Administrator' role"
    exit 1
fi

# Test 2: Can we list federated credentials?
echo "2. Testing READ access to federated credentials..."
if az ad app federated-credential list --id "$APP_ID" &> /dev/null; then
    echo "   ✓ Can list federated credentials"
else
    echo "   ❌ Cannot list federated credentials"
    exit 1
fi

# Test 3: Can we create federated credentials?
echo "3. Testing WRITE access (dry-run)..."
echo "   This requires one of these Azure AD roles:"
echo "   - Application Administrator"
echo "   - Cloud Application Administrator"
echo "   - Global Administrator"
echo "   - App registration owner"
echo ""

# Check if we're owner
APP_OWNER=$(az ad app owner list --id "$APP_ID" --query "[?userPrincipalName=='$ACCOUNT_NAME'].userPrincipalName" -o tsv 2>/dev/null || echo "")

if [ -n "$APP_OWNER" ]; then
    echo "   ✓ You are an owner of this app registration"
    echo ""
    echo "✅ You have the necessary permissions!"
else
    echo "   ℹ️  Cannot determine if you're an owner (this is okay)"
    echo ""
    echo "⚠️  You likely have permissions if steps 1-2 passed"
    echo "   If the next step fails, contact your Azure AD admin"
fi

echo ""
echo "=============================="
echo "Ready to create federated credentials!"
echo ""
echo "Run: ./.azure_pipelines/scripts/create-dev-credential.sh"

