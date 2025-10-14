# Quick Fix Guide - Pipeline Errors

This guide helps you quickly resolve common pipeline errors.

## ❌ Error: Environment could not be found

**Error Message:**
```
Environment evo-taskers-dev could not be found. 
The environment does not exist or has not been authorized for use.
```

### Solution: Create Environments

Environments must be created in Azure DevOps before pipelines can use them.

#### Option 1: Automated (Recommended)

```bash
cd pipelines/setup
# Edit the script first to set your organization and project
nano create-environments.sh

# Run the script
./create-environments.sh
```

#### Option 2: Manual Creation

1. Navigate to **Pipelines** → **Environments** in Azure DevOps
2. Click **New environment**
3. Create these environments:

**For Landing Zone Pipeline:**
- `evo-taskers-dev`
- `evo-taskers-qa`
- `evo-taskers-prod` ⚠️ (configure approval)

**For Application Pipelines:**
- `evo-taskers-automateddatafeed-dev`
- `evo-taskers-automateddatafeed-qa`
- `evo-taskers-automateddatafeed-prod` ⚠️ (configure approval)
- `evo-taskers-dashboard-dev`
- `evo-taskers-dashboard-qa`
- `evo-taskers-dashboard-prod` ⚠️ (configure approval)
- `evo-taskers-dashboardfrontend-dev`
- `evo-taskers-dashboardfrontend-qa`
- `evo-taskers-dashboardfrontend-prod` ⚠️ (configure approval)
- `evo-taskers-sendgridfunction-dev`
- `evo-taskers-sendgridfunction-qa`
- `evo-taskers-sendgridfunction-prod` ⚠️ (configure approval)
- `evo-taskers-unlockbookings-dev`
- `evo-taskers-unlockbookings-qa`
- `evo-taskers-unlockbookings-prod` ⚠️ (configure approval)
- `evo-taskers-autoopenshorex-dev`
- `evo-taskers-autoopenshorex-qa`
- `evo-taskers-autoopenshorex-prod` ⚠️ (configure approval)

#### Configure Production Approvals

For all `*-prod` environments:

1. Click on the environment name
2. Click **...** → **Approvals and checks**
3. Click **Approvals**
4. Add approvers (yourself or team members)
5. Set minimum approvers: 1 (or 2 for better safety)
6. Set timeout: 30 minutes
7. Add instructions: "Please review Terraform plan before approving"
8. Click **Create**

---

## ✅ Error: TerraformInstaller is ambiguous

**Error Message:**
```
The task name TerraformInstaller is ambiguous. 
Specify one of the following identifiers...
```

### Solution: Use Fully Qualified Task Name

**Status:** ✅ **FIXED** in the pipeline files

The templates now use the full task identifier:
```yaml
ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@1
```

No action needed - just pull the latest changes.

---

## ❌ Error: Service connection not found

**Error Message:**
```
Service connection 'Azure-Dev-ServiceConnection' could not be found
```

### Solution: Create Service Connections

See: [create-service-connections.md](./create-service-connections.md)

**Quick steps:**

1. Go to **Project Settings** → **Service connections**
2. Click **New service connection** → **Azure Resource Manager**
3. Select **Service principal (automatic)**
4. Select your subscription
5. Name it exactly as expected:
   - `Azure-Dev-ServiceConnection`
   - `Azure-QA-ServiceConnection`
   - `Azure-Prod-ServiceConnection`
6. Grant access permission to all pipelines (for now)
7. Click **Save**

---

## ❌ Error: Variable not found

**Error Message:**
```
The variable group 'terraform-backend' could not be found
```

### Solution: Create Variable Groups

See: [VARIABLE-GROUPS.md](./VARIABLE-GROUPS.md)

**Quick steps:**

```bash
cd pipelines/setup
# Edit the script first
nano create-variable-groups.sh

# Run the script
./create-variable-groups.sh
```

Or create manually:

1. Go to **Pipelines** → **Library**
2. Click **+ Variable group**
3. Name: `terraform-backend`
4. Add variables:
   - `BACKEND_RESOURCE_GROUP_NAME`
   - `BACKEND_STORAGE_ACCOUNT_NAME`
   - `BACKEND_CONTAINER_NAME`
5. Check **Allow access to all pipelines**
6. Click **Save**

Repeat for:
- `evo-taskers-common`
- `evo-taskers-apps`

---

## ❌ Error: Backend initialization failed

**Error Message:**
```
Error: Failed to get existing workspaces
```

### Solution: Verify Backend Storage

Check that the backend storage account exists:

```bash
# Verify storage account
az storage account show \
  --name <storage-account-name> \
  --resource-group <resource-group-name>

# Check container exists
az storage container show \
  --name tfstate \
  --account-name <storage-account-name>
```

If not created, run:

```bash
cd backend-setup-scripts
./setup-terraform-state.sh
```

---

## ❌ Error: Permission denied

**Error Message:**
```
The client does not have authorization to perform action
```

### Solution: Grant Service Principal Permissions

```bash
# Get service principal ID from service connection
# Then grant permissions:

az role assignment create \
  --assignee <service-principal-id> \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>

# Also grant for RBAC operations:
az role assignment create \
  --assignee <service-principal-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>
```

---

## 🔍 Debugging Tips

### Check Pipeline Run

1. Go to failed pipeline run
2. Click on failed job
3. Expand failed task
4. Review logs carefully

### Verify Configuration

```bash
# Check current working directory
pwd

# List files
ls -la

# Check if terraform files exist
ls *.tf

# Verify backend config was created
cat backend-config.tfvars
```

### Test Locally (if possible)

```bash
cd project/evo-taskers/common

# Test backend init
terraform init \
  -backend-config="resource_group_name=..." \
  -backend-config="storage_account_name=..." \
  -backend-config="container_name=tfstate" \
  -backend-config="key=test.tfstate"

# If successful, the issue is with pipeline configuration
# If failed, the issue is with backend or Terraform code
```

---

## 📋 Pre-Flight Checklist

Before running pipelines, ensure:

**Azure Infrastructure:**
- [ ] Backend storage account created
- [ ] Storage container exists
- [ ] Service principals created (or will use automatic)

**Azure DevOps:**
- [ ] Service connections created
- [ ] Variable groups created and populated
- [ ] Environments created
- [ ] Production approvals configured
- [ ] Pipeline has access to variable groups

**Repository:**
- [ ] Backend configs fixed (no hardcoded values)
- [ ] Terraform code validated locally
- [ ] All files committed and pushed

---

## 🆘 Still Stuck?

1. **Review full setup guide:** [COMPLETE-SETUP-GUIDE.md](./COMPLETE-SETUP-GUIDE.md)
2. **Check documentation:** [../README.md](../README.md)
3. **Review pipeline logs:** Click on failed task in Azure DevOps
4. **Test locally:** Run terraform commands manually to isolate issue
5. **Contact support:** Reach out to DevOps team with:
   - Pipeline run URL
   - Error message
   - What you've tried
   - Screenshots

---

## ✅ Success Indicators

Your pipeline is working correctly when:

- ✅ Pipeline runs without errors
- ✅ Terraform init succeeds
- ✅ Terraform plan completes
- ✅ Terraform validate passes
- ✅ Security scan runs (may have warnings, but shouldn't fail)
- ✅ Plan output looks correct
- ✅ Artifacts are published

---

**Quick Setup Order:**

1. Create backend storage → `backend-setup-scripts/setup-terraform-state.sh`
2. Create service connections → Azure DevOps UI
3. Create variable groups → `./create-variable-groups.sh`
4. Create environments → `./create-environments.sh`
5. Fix backends → `./fix-backend-configs.sh`
6. Run pipeline → Should work now!

Good luck! 🚀

