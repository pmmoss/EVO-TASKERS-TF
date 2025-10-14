# Complete Setup Guide: Azure DevOps Pipelines for Terraform

This is a comprehensive, step-by-step guide to set up Azure DevOps pipelines for deploying Terraform infrastructure with best practices.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Azure subscriptions (Dev, QA, Prod) or separate resource groups
- [ ] Azure DevOps organization and project
- [ ] Owner or Contributor access to Azure subscriptions
- [ ] Project Administrator access in Azure DevOps
- [ ] Azure CLI installed locally
- [ ] Terraform installed locally (for testing)
- [ ] Git repository set up in Azure Repos

## 🎯 Setup Overview

```
1. Azure Setup (30 min)
   └─ Create subscriptions/RGs
   └─ Create state storage
   └─ Create service principals

2. Azure DevOps Setup (45 min)
   └─ Create service connections
   └─ Create variable groups
   └─ Create environments
   └─ Configure approvals

3. Repository Setup (30 min)
   └─ Fix backend configs
   └─ Create pipelines
   └─ Configure branch policies

4. Testing & Validation (30 min)
   └─ Test dev deployment
   └─ Test QA deployment
   └─ Test prod deployment (with approval)

Total: ~2-3 hours
```

## Part 1: Azure Setup (30 minutes)

### Step 1.1: Verify Subscriptions

```bash
# List all subscriptions you have access to
az account list --output table

# Note down your subscription IDs:
# Dev:  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# QA:   yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
# Prod: zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
```

**Decision Point**: 
- ✅ **Recommended**: Separate subscriptions for each environment
- ⚠️ **Alternative**: Separate resource groups in single subscription
- ❌ **Not Recommended**: Single resource group for all environments

### Step 1.2: Create Terraform State Storage

This storage account will hold all Terraform state files.

```bash
# Set variables
LOCATION="westus2"
BACKEND_RG="rg-terraform-state"
BACKEND_SA="stterraformstate$RANDOM"
CONTAINER="tfstate"

# Login and set subscription (use the subscription where you want state stored)
az login
az account set --subscription "<your-subscription-id>"

# Create resource group
az group create \
  --name $BACKEND_RG \
  --location $LOCATION \
  --tags Environment=Shared Purpose="Terraform State"

# Create storage account
az storage account create \
  --name $BACKEND_SA \
  --resource-group $BACKEND_RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# Create container
az storage container create \
  --name $CONTAINER \
  --account-name $BACKEND_SA \
  --public-access off

# Enable versioning
az storage account blob-service-properties update \
  --account-name $BACKEND_SA \
  --enable-versioning true

# Enable soft delete
az storage account blob-service-properties update \
  --account-name $BACKEND_SA \
  --enable-delete-retention true \
  --delete-retention-days 30

# Save these values - you'll need them later!
echo "✅ Backend Storage Created:"
echo "  Resource Group: $BACKEND_RG"
echo "  Storage Account: $BACKEND_SA"
echo "  Container: $CONTAINER"
```

**Save these values** - you'll need them for variable groups!

### Step 1.3: Create Service Principals (Optional but Recommended)

For better control, create service principals manually:

```bash
# Dev Service Principal
DEV_SUB_ID="<your-dev-subscription-id>"
az ad sp create-for-rbac \
  --name "sp-evo-taskers-terraform-dev" \
  --role Contributor \
  --scopes /subscriptions/$DEV_SUB_ID

# Save the output! You'll need:
# - appId (Client ID)
# - password (Client Secret)
# - tenant (Tenant ID)

# Grant additional permissions for RBAC
az role assignment create \
  --assignee <appId-from-above> \
  --role "User Access Administrator" \
  --scope /subscriptions/$DEV_SUB_ID

# QA Service Principal
QA_SUB_ID="<your-qa-subscription-id>"
az ad sp create-for-rbac \
  --name "sp-evo-taskers-terraform-qa" \
  --role Contributor \
  --scopes /subscriptions/$QA_SUB_ID

az role assignment create \
  --assignee <appId-from-above> \
  --role "User Access Administrator" \
  --scope /subscriptions/$QA_SUB_ID

# Prod Service Principal
PROD_SUB_ID="<your-prod-subscription-id>"
az ad sp create-for-rbac \
  --name "sp-evo-taskers-terraform-prod" \
  --role Contributor \
  --scopes /subscriptions/$PROD_SUB_ID

az role assignment create \
  --assignee <appId-from-above> \
  --role "User Access Administrator" \
  --scope /subscriptions/$PROD_SUB_ID
```

**IMPORTANT**: Store these credentials securely (Azure Key Vault recommended).

---

## Part 2: Azure DevOps Setup (45 minutes)

### Step 2.1: Create Service Connections

#### Option A: Automatic (Easier)

1. Open Azure DevOps → Your Project
2. Go to **Project Settings** (bottom left)
3. Under **Pipelines**, click **Service connections**
4. Click **New service connection** → **Azure Resource Manager** → **Next**
5. Select **Service principal (automatic)**
6. Configure:
   - **Scope level**: Subscription
   - **Subscription**: Select Dev subscription
   - **Service connection name**: `Azure-Dev-ServiceConnection`
   - **Description**: Service connection for Dev environment
   - **Security**: ✅ Grant access permission to all pipelines (for now)
7. Click **Save**
8. Repeat for QA and Prod with names:
   - `Azure-QA-ServiceConnection`
   - `Azure-Prod-ServiceConnection`

#### Option B: Manual (More Control)

If you created service principals in Step 1.3:

1. Select **Service principal (manual)**
2. Enter the details from the service principal creation:
   - **Subscription ID**: `<subscription-id>`
   - **Subscription Name**: `<subscription-name>`
   - **Service Principal ID**: `<appId from sp creation>`
   - **Service Principal Key**: `<password from sp creation>`
   - **Tenant ID**: `<tenant from sp creation>`
3. Click **Verify** to test
4. Enter service connection name and save
5. Repeat for each environment

### Step 2.2: Create Variable Groups

#### Option A: Using Script (Automated)

```bash
# Configure Azure DevOps CLI
az extension add --name azure-devops

# Set defaults (replace with your values)
ORG="https://dev.azure.com/YOUR-ORG"
PROJECT="YOUR-PROJECT"

az devops configure --defaults organization=$ORG project=$PROJECT

# Login if needed
az devops login

# Run the creation script
cd pipelines/setup
chmod +x create-variable-groups.sh

# Edit the script first to set your values!
nano create-variable-groups.sh

# Run it
./create-variable-groups.sh
```

#### Option B: Manual Creation (Recommended for first time)

1. Navigate to **Pipelines** → **Library**
2. Click **+ Variable group**

**Variable Group 1: terraform-backend**

```
Name: terraform-backend
Description: Terraform backend configuration

Variables:
├─ BACKEND_RESOURCE_GROUP_NAME    = rg-terraform-state
├─ BACKEND_STORAGE_ACCOUNT_NAME   = stterraformstate<your-value>
├─ BACKEND_CONTAINER_NAME         = tfstate
└─ BACKEND_SUBSCRIPTION_ID        = <backend-subscription-id>

☑ Allow access to all pipelines
```

**Variable Group 2: evo-taskers-common**

```
Name: evo-taskers-common
Description: Common infrastructure variables

Variables:
├─ DEV_SERVICE_CONNECTION     = Azure-Dev-ServiceConnection
├─ QA_SERVICE_CONNECTION      = Azure-QA-ServiceConnection
├─ PROD_SERVICE_CONNECTION    = Azure-Prod-ServiceConnection
├─ DEV_SUBSCRIPTION_ID        = <dev-sub-id>
├─ QA_SUBSCRIPTION_ID         = <qa-sub-id>
└─ PROD_SUBSCRIPTION_ID       = <prod-sub-id>

☑ Allow access to all pipelines (or specific)
```

**Variable Group 3: evo-taskers-apps**

```
Name: evo-taskers-apps
Description: Application workloads variables

Variables:
├─ DEV_SERVICE_CONNECTION     = Azure-Dev-ServiceConnection
├─ QA_SERVICE_CONNECTION      = Azure-QA-ServiceConnection
├─ PROD_SERVICE_CONNECTION    = Azure-Prod-ServiceConnection
├─ DEV_SUBSCRIPTION_ID        = <dev-sub-id>
├─ QA_SUBSCRIPTION_ID         = <qa-sub-id>
└─ PROD_SUBSCRIPTION_ID       = <prod-sub-id>

☑ Allow access to all pipelines (or specific)
```

3. Click **Save** for each variable group

### Step 2.3: Create Environments

Environments enable approval gates and deployment history.

1. Navigate to **Pipelines** → **Environments**
2. Click **New environment**
3. Create these environments:

```
Environment Name: evo-taskers-dev
Description: Development environment for EVO TASKERS
Resource: None (leave empty)
```

Repeat for:
- `evo-taskers-qa` (QA environment)
- `evo-taskers-prod` (Production environment)
- `evo-taskers-automateddatafeed-dev`
- `evo-taskers-automateddatafeed-qa`
- `evo-taskers-automateddatafeed-prod`
- (Similar for each application: dashboard, dashboardfrontend, sendgridfunction, unlockbookings, autoopenshorex)

**Quick creation tip**: You can create environments automatically when first pipeline runs, but pre-creating them allows you to set up approvals first.

### Step 2.4: Configure Approvals for Production

1. Go to **Pipelines** → **Environments**
2. Click on `evo-taskers-prod`
3. Click **...** (menu) → **Approvals and checks**
4. Click **Approvals**
5. Configure:
   - **Approvers**: Add yourself and/or other team members
   - **Minimum number of approvers**: 1 (or 2 for better safety)
   - **Timeout**: 30 minutes (or adjust as needed)
   - **Instructions**: "Please review the Terraform plan before approving"
6. Click **Create**

Repeat for all production environments:
- `evo-taskers-prod`
- `evo-taskers-automateddatafeed-prod`
- `evo-taskers-dashboard-prod`
- etc.

---

## Part 3: Repository Setup (30 minutes)

### Step 3.1: Fix Backend Configurations

Your current backend.tf files have hardcoded subscription IDs. Let's fix them:

```bash
# Navigate to your repository
cd /path/to/EVO-TASKERS-TF

# Run the fix script
cd pipelines/setup
chmod +x fix-backend-configs.sh
./fix-backend-configs.sh

# Review the changes
git diff
```

The script will:
- ✅ Backup all backend.tf files
- ✅ Remove hardcoded subscription_id
- ✅ Update to use environment variables
- ✅ Update backend configuration to use pipeline variables

**Manual Alternative**: If you prefer manual updates, edit each `backend.tf` to:

```hcl
terraform {
  required_version = ">=1.2"
  
  backend "azurerm" {
    # Configuration provided by pipeline via -backend-config
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46"
    }
  }
}

provider "azurerm" {
  # subscription_id from ARM_SUBSCRIPTION_ID env var (service connection)
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
```

### Step 3.2: Commit and Push Changes

```bash
# Create a feature branch
git checkout -b feature/azure-devops-pipelines

# Add all the new pipeline files
git add pipelines/
git add backend-config/

# Commit backend fixes
git add project/*/backend.tf global/backend.tf
git commit -m "fix: Remove hardcoded credentials from backend configurations"

# Commit pipeline files
git add pipelines/
git commit -m "feat: Add Azure DevOps pipelines for Terraform deployments

- Multi-stage pipelines for landing zone and applications
- Environment promotion (Dev → QA → Prod)
- Security scanning with Checkov
- Reusable templates
- Comprehensive documentation"

# Push to remote
git push origin feature/azure-devops-pipelines
```

### Step 3.3: Create Pipelines in Azure DevOps

#### Create Landing Zone Pipeline

1. Navigate to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git** (or your source)
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Path: `/pipelines/landing-zone-pipeline.yml`
7. Click **Continue**
8. Review the YAML
9. Click **Save** (don't run yet)
10. Rename to: "Landing Zone - Terraform"

#### Create Applications Pipeline

1. Click **New pipeline** again
2. Select **Azure Repos Git**
3. Select your repository
4. Choose **Existing Azure Pipelines YAML file**
5. Path: `/pipelines/applications-pipeline.yml`
6. Click **Continue**
7. Review the YAML
8. Click **Save**
9. Rename to: "Applications - Terraform"

### Step 3.4: Configure Branch Policies

Protect your main branch:

1. Go to **Repos** → **Branches**
2. Find `main` branch → Click **...** → **Branch policies**
3. Configure:

```
☑ Require a minimum number of reviewers
  ├─ Minimum: 1
  ├─ ☑ Allow requestors to approve their own changes (for testing, disable later)
  └─ ☑ Reset code reviewer votes when there are new changes

☑ Check for linked work items
  └─ Required

☑ Check for comment resolution
  └─ Required

Build Validation:
  ├─ + Add build policy
  ├─ Build pipeline: Landing Zone - Terraform
  ├─ Trigger: Automatic
  ├─ Policy requirement: Required
  └─ Build expiration: 12 hours
```

4. Click **Save**

Repeat similar policies for `develop` branch (less strict).

---

## Part 4: Testing & Validation (30 minutes)

### Step 4.1: Test Variable Groups

Create a test pipeline:

```yaml
# test-variables.yml
trigger: none
pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: 'terraform-backend'
  - group: 'evo-taskers-common'

steps:
  - bash: |
      echo "Testing variable groups..."
      echo "Backend RG: $(BACKEND_RESOURCE_GROUP_NAME)"
      echo "Backend SA: $(BACKEND_STORAGE_ACCOUNT_NAME)"
      echo "Dev Connection: $(DEV_SERVICE_CONNECTION)"
      
      if [ -z "$(BACKEND_RESOURCE_GROUP_NAME)" ]; then
        echo "##vso[task.logissue type=error]BACKEND_RESOURCE_GROUP_NAME not set!"
        exit 1
      fi
      
      echo "✅ All variables configured correctly"
    displayName: 'Validate Variables'
```

Run this pipeline to verify variables are accessible.

### Step 4.2: Test Service Connections

```yaml
# test-connections.yml
trigger: none
pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: 'evo-taskers-common'

steps:
  - task: AzureCLI@2
    displayName: 'Test Dev Connection'
    inputs:
      azureSubscription: '$(DEV_SERVICE_CONNECTION)'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        echo "Testing Dev service connection..."
        az account show
        az group list --query "[].name" -o table
```

### Step 4.3: Deploy to Dev Environment

1. Merge your feature branch to `develop`:
```bash
# Create pull request
git checkout develop
git merge feature/azure-devops-pipelines
git push origin develop
```

2. Navigate to **Pipelines** → **Landing Zone - Terraform**
3. Click **Run pipeline**
4. Select branch: `develop`
5. Click **Run**
6. Monitor the pipeline execution

**Expected flow**:
- ✅ Plan Dev (should succeed)
- ✅ Apply Dev (should deploy infrastructure)
- ✅ Plan QA (should succeed)
- ⏸️ Apply QA (may wait for approval if configured)

### Step 4.4: Validate Deployment

```bash
# Check resources were created
az group list --query "[?contains(name, 'evo-taskers-dev')]" -o table

# Check specific resource group
az resource list --resource-group rg-evotaskers-dev-wus2 -o table

# Check Terraform state
az storage blob list \
  --container-name tfstate \
  --account-name <your-storage-account> \
  --query "[].name" -o table
```

### Step 4.5: Deploy to Production

1. Create a pull request from `develop` to `main`
2. Get approval
3. Merge to `main`
4. Navigate to **Pipelines**
5. The production pipeline should start automatically
6. **Wait for approval notification**
7. Review the plan in pipeline logs
8. Approve or reject

**Expected flow**:
- ✅ Plan Prod (should succeed)
- ⏸️ Waiting for approval
- (After approval) ✅ Apply Prod

---

## 🎉 Success Criteria

Your setup is complete when:

- [ ] All variable groups created and populated
- [ ] All service connections working
- [ ] All environments created with approvals
- [ ] Backend configurations fixed (no hardcoded values)
- [ ] Pipelines created and validated
- [ ] Dev deployment successful
- [ ] QA deployment successful
- [ ] Prod deployment successful (with approval)
- [ ] Branch policies configured
- [ ] Team members added as approvers

---

## 🔐 Security Checklist

Before going to production:

- [ ] Rotate service principal credentials
- [ ] Remove "Grant access to all pipelines" from prod variable groups
- [ ] Configure specific pipeline permissions
- [ ] Enable audit logs in Azure DevOps
- [ ] Configure security scanning (Checkov is included)
- [ ] Set up monitoring and alerts
- [ ] Document security procedures
- [ ] Configure Azure Policy for compliance
- [ ] Enable MFA for all team members
- [ ] Review RBAC assignments

---

## 📚 Next Steps

After successful setup:

1. **Deploy remaining applications**: Use the applications pipeline
2. **Set up monitoring**: Configure alerts for pipeline failures
3. **Document runbooks**: Create operational procedures
4. **Train team**: Ensure everyone understands the pipeline
5. **Regular reviews**: Schedule monthly security and access reviews

---

## 🆘 Troubleshooting

### Service Connection Fails

```bash
# Verify service principal has correct permissions
az role assignment list --assignee <sp-app-id> --output table

# Grant additional permissions if needed
az role assignment create \
  --assignee <sp-app-id> \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>
```

### Variable Not Found

- Verify variable group name matches exactly in YAML
- Check variable group permissions
- Ensure pipeline authorized to use variable group

### Backend Init Fails

```bash
# Verify storage account exists and is accessible
az storage account show \
  --name <storage-account> \
  --resource-group <rg>

# Check service principal has access
az role assignment create \
  --assignee <sp-app-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<sa>
```

### Pipeline Doesn't Trigger

- Check trigger conditions in YAML
- Verify path filters
- Check branch policies aren't blocking
- Ensure repository permissions

---

## 📞 Support

For additional help:

1. Review pipeline logs in Azure DevOps
2. Check [Azure DevOps documentation](https://docs.microsoft.com/azure/devops)
3. Review [Terraform documentation](https://www.terraform.io/docs)
4. Contact DevOps team

---

## ✅ Completion

Congratulations! You now have a production-ready Azure DevOps pipeline for Terraform deployments with:

- ✅ Infrastructure as Code
- ✅ Multi-environment support
- ✅ Security scanning
- ✅ Approval workflows
- ✅ No hardcoded credentials
- ✅ Best practices implementation

**Next**: Start deploying your applications! 🚀

