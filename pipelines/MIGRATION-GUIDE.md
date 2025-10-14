# Migration Guide: From Manual Terraform to Azure DevOps Pipelines

This guide helps teams transition from manual Terraform deployments with hardcoded values to automated Azure DevOps pipelines.

## 📋 Migration Overview

### What's Changing

```
Before (Manual):
├─ Hardcoded subscription IDs in backend.tf
├─ Hardcoded backend storage in backend.tf
├─ Manual terraform init/plan/apply
├─ No approval workflow
└─ Individual developer credentials

After (Automated):
├─ Dynamic subscription IDs via service connections
├─ Parameterized backend configuration
├─ Automated pipelines with approvals
├─ Environment-based deployments
└─ Service principal authentication
```

### Benefits

- ✅ **No hardcoded credentials**: All secrets via service connections
- ✅ **Consistent deployments**: Same process for all environments
- ✅ **Audit trail**: All changes tracked in pipeline history
- ✅ **Approval gates**: Required approvals for production
- ✅ **Security scanning**: Automatic Checkov scans
- ✅ **Team collaboration**: Multiple developers, no conflicts

## 🎯 Migration Phases

### Phase 1: Preparation (No disruption)
- Set up Azure DevOps infrastructure
- Create service connections and variable groups
- Create pipelines (don't run yet)
- Test in isolated environment

### Phase 2: Backend Migration (Minimal disruption)
- Backup existing state files
- Update backend.tf files
- Migrate state to new backend (if needed)
- Test backend connectivity

### Phase 3: Pipeline Deployment (Controlled rollout)
- Deploy Dev via pipeline
- Validate against manual deployment
- Deploy QA via pipeline
- Deploy Prod via pipeline (with extra caution)

### Phase 4: Cutover (Switch to pipelines)
- Disable manual deployments
- Enable branch policies
- Train team on new process
- Monitor and adjust

---

## Phase 1: Preparation (1-2 days)

### Step 1.1: Document Current State

Before making any changes, document your current setup:

```bash
# Export current Terraform state
cd project/evo-taskers/common
terraform state pull > ../../../migration/state-backup-common-$(date +%Y%m%d).json

# Document current resources
terraform state list > ../../../migration/resources-common-$(date +%Y%m%d).txt

# Document current outputs
terraform output -json > ../../../migration/outputs-common-$(date +%Y%m%d).json

# Repeat for each application
```

Create a checklist:

```
Current State Inventory:
├─ [ ] Common infrastructure resources documented
├─ [ ] Each application resources documented
├─ [ ] All state files backed up
├─ [ ] All outputs documented
├─ [ ] Current backend configuration documented
├─ [ ] Current subscription IDs documented
└─ [ ] Current service principal info (if any)
```

### Step 1.2: Set Up Azure DevOps (No impact on production)

Follow the [Complete Setup Guide](./setup/COMPLETE-SETUP-GUIDE.md):

1. ✅ Create service connections
2. ✅ Create variable groups
3. ✅ Create environments
4. ✅ Configure approvals
5. ✅ Create pipelines (save, don't run)

**Important**: Don't run pipelines yet! Just set them up.

### Step 1.3: Test in Isolated Environment

Create a test deployment to validate pipeline:

```bash
# Create a test resource group
az group create --name rg-pipeline-test --location westus2

# Update dev.tfvars with test values
# Run pipeline in test mode
```

Validate:
- ✅ Pipeline can authenticate
- ✅ Backend state works
- ✅ Terraform plan succeeds
- ✅ Terraform apply succeeds
- ✅ Resources created correctly

---

## Phase 2: Backend Migration (2-3 hours)

### Step 2.1: Backup Everything

**Critical**: Always backup before migration!

```bash
# Create backup directory
mkdir -p migration/backups/$(date +%Y%m%d)

# Backup all state files from Azure Storage
az storage blob download-batch \
  --source tfstate \
  --destination migration/backups/$(date +%Y%m%d) \
  --account-name <current-storage-account> \
  --pattern "*.tfstate*"

# Backup all backend.tf files
find . -name "backend.tf" -exec cp {} migration/backups/$(date +%Y%m%d)/{} \;

# Verify backups
ls -lR migration/backups/$(date +%Y%m%d)
```

### Step 2.2: Update Backend Configurations

Run the fix script:

```bash
cd pipelines/setup
chmod +x fix-backend-configs.sh
./fix-backend-configs.sh
```

This will:
- Backup original backend.tf files
- Remove hardcoded subscription_id
- Update backend configuration format

### Step 2.3: Test Backend Migration (Dev First)

Test the new backend configuration in Dev:

```bash
cd project/evo-taskers/common

# Remove local state (keep backup!)
mv terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
rm -rf .terraform/

# Initialize with new backend config
terraform init \
  -backend-config="resource_group_name=<backend-rg>" \
  -backend-config="storage_account_name=<backend-sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=landing-zone/evo-taskers-common-dev.tfstate"

# Verify state
terraform state list

# Compare with backup
diff <(terraform state list) <(terraform state list -state=terraform.tfstate.backup.$(date +%Y%m%d))
```

### Step 2.4: Migrate State to New Backend (If Changing)

**Only if you're moving to a new storage account:**

```bash
# Option 1: Terraform state migration
terraform init \
  -migrate-state \
  -backend-config="resource_group_name=<new-backend-rg>" \
  -backend-config="storage_account_name=<new-backend-sa>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=landing-zone/evo-taskers-common-dev.tfstate"

# Option 2: Manual state copy (if preferred)
az storage blob copy start \
  --source-account-name <old-sa> \
  --source-container tfstate \
  --source-blob <old-key> \
  --destination-account-name <new-sa> \
  --destination-container tfstate \
  --destination-blob <new-key>
```

### Step 2.5: Validation Checklist

After backend migration:

```
Validation:
├─ [ ] terraform init succeeds
├─ [ ] terraform plan shows no changes (if no actual changes)
├─ [ ] terraform state list matches backup
├─ [ ] All resources visible in state
├─ [ ] Backend accessible from Azure DevOps pipeline
└─ [ ] Original state backed up and safe
```

---

## Phase 3: Pipeline Deployment (1-2 days)

### Step 3.1: Deploy Dev via Pipeline

**First deployment is critical!**

1. Commit backend changes to feature branch:
```bash
git checkout -b feature/pipeline-migration
git add project/*/backend.tf
git commit -m "refactor: Update backend configs for pipeline deployment"
git push origin feature/pipeline-migration
```

2. Merge to `develop` branch (triggers Dev pipeline)

3. Monitor pipeline execution closely:
   - Watch each step
   - Review plan output carefully
   - Compare with expected changes
   - Check for any drift

4. Validate deployment:
```bash
# Check resources
az resource list --resource-group rg-evotaskers-dev-wus2 -o table

# Compare with pre-migration inventory
diff migration/resources-common-$(date +%Y%m%d).txt <(terraform state list)

# Validate outputs
terraform output
```

### Step 3.2: Parallel Validation

Run a manual plan to compare with pipeline:

```bash
# Manual plan (for comparison)
cd project/evo-taskers/common
terraform workspace select dev
terraform plan -var-file=dev.tfvars -out=manual.tfplan

# Pipeline plan is saved as artifact
# Download and compare:
az pipelines runs artifact download \
  --artifact-name tfplan-dev \
  --run-id <run-id> \
  --path ./pipeline-plan

# Compare (should be identical)
diff <(terraform show manual.tfplan) <(terraform show pipeline-plan/tfplan)
```

### Step 3.3: Deploy QA via Pipeline

Once Dev is validated:

1. QA should deploy automatically after Dev (if configured)
2. Or manually trigger QA stage
3. Perform same validation as Dev
4. Compare QA resources with previous state

### Step 3.4: Deploy Production via Pipeline

**Extra caution for Production!**

1. Create PR from `develop` to `main`
2. Add detailed description of changes
3. Get approval from team lead
4. Merge to `main` (triggers Prod pipeline)
5. **Review plan output extensively**
6. Check for any unexpected changes
7. Approve deployment
8. Monitor deployment closely
9. Validate production resources

### Step 3.5: Rollback Plan

If something goes wrong:

```bash
# Quick rollback: Restore state from backup
cd project/evo-taskers/common

# Stop any running operations
# Download backup state
az storage blob download \
  --container-name tfstate \
  --name landing-zone/evo-taskers-common-prod.tfstate \
  --file terraform.tfstate.backup \
  --account-name <backup-storage>

# Upload backup as current state
az storage blob upload \
  --container-name tfstate \
  --name landing-zone/evo-taskers-common-prod.tfstate \
  --file terraform.tfstate.backup \
  --account-name <current-storage> \
  --overwrite

# Re-init and verify
terraform init
terraform state list
```

---

## Phase 4: Cutover (1 day)

### Step 4.1: Enable Governance

Now that pipelines work, enforce their use:

1. **Branch Policies**:
```
Main branch:
├─ Require PR
├─ Require 2 reviewers
├─ Require build validation
└─ Require work item linking

Develop branch:
├─ Require PR
└─ Require 1 reviewer
```

2. **Environment Approvals**:
   - Add multiple approvers for prod
   - Add timeout settings
   - Add deployment instructions

3. **Pipeline Permissions**:
   - Remove "Grant access to all pipelines" from prod
   - Explicitly authorize pipelines
   - Review service connection permissions

### Step 4.2: Disable Manual Access

Prevent manual Terraform operations:

```bash
# Option 1: Remove local Terraform state
# (Developers can still run plan locally)
rm -rf .terraform/
rm terraform.tfstate*

# Option 2: Remove Contributor access for individuals
# Grant access only to service principals
az role assignment delete \
  --assignee <user-email> \
  --role Contributor \
  --scope /subscriptions/<prod-sub-id>

# Grant access to Azure DevOps service principal instead
az role assignment create \
  --assignee <sp-app-id> \
  --role Contributor \
  --scope /subscriptions/<prod-sub-id>
```

### Step 4.3: Train Team

Conduct training sessions:

**Topics to cover**:
1. New deployment workflow
2. How to trigger pipelines
3. How to review and approve deployments
4. Troubleshooting common issues
5. Emergency procedures
6. Rollback process

**Hands-on exercises**:
- Create a feature branch
- Make a Terraform change
- Create PR and get review
- Watch pipeline deploy to Dev
- Approve QA deployment
- Simulate production deployment

### Step 4.4: Update Documentation

Update all operational docs:

- ✅ Deployment runbooks
- ✅ Emergency procedures
- ✅ Troubleshooting guides
- ✅ Architecture diagrams
- ✅ Access control matrix
- ✅ Approval workflows

### Step 4.5: Set Up Monitoring

Configure alerts for:

```yaml
Alerts:
├─ Pipeline failures
├─ Approval timeouts
├─ Terraform drift detection
├─ Unauthorized state access
├─ Failed security scans
└─ Unusual activity
```

Example Azure Monitor alert:

```bash
az monitor metrics alert create \
  --name "Pipeline-Failure-Alert" \
  --resource-group <rg> \
  --scopes <pipeline-resource-id> \
  --condition "avg Failed runs > 0" \
  --description "Alert when pipeline fails" \
  --evaluation-frequency 5m \
  --window-size 5m \
  --action <action-group-id>
```

---

## 🔍 Validation & Testing

### Daily Checks (First Week)

```bash
# Check pipeline runs
az pipelines runs list --top 10 --output table

# Check state file access
az storage blob list \
  --container-name tfstate \
  --account-name <storage-account> \
  --query "[?properties.lastModified >= '2024-01-01'].name" \
  --output table

# Verify no drift
terraform plan -detailed-exitcode
# Exit code 0 = no changes (good)
# Exit code 2 = changes detected (investigate)
```

### Weekly Reviews (First Month)

- [ ] Review all pipeline runs
- [ ] Check approval times
- [ ] Review security scan results
- [ ] Check for any failed deployments
- [ ] Review state file access logs
- [ ] Verify backups are working

### Success Metrics

Track these metrics:

```
Success Criteria:
├─ 100% of deployments via pipeline
├─ Zero manual state modifications
├─ All production changes approved
├─ No hardcoded credentials
├─ Average approval time < 30 minutes
├─ Pipeline success rate > 95%
└─ Zero security findings in prod
```

---

## 🆘 Troubleshooting Migration Issues

### Issue: State Lock During Migration

**Symptom**: "Error acquiring the state lock"

**Solution**:
```bash
# List all locks
az storage blob lease list \
  --container-name tfstate \
  --account-name <storage-account>

# If stuck, break lease (use carefully!)
az storage blob lease break \
  --blob-name <blob-name> \
  --container-name tfstate \
  --account-name <storage-account>
```

### Issue: Pipeline Shows Changes When None Expected

**Symptom**: Terraform plan shows changes after migration

**Causes**:
1. Drift - resources changed outside Terraform
2. Provider version difference
3. State file corruption

**Solution**:
```bash
# Refresh state
terraform refresh -var-file=dev.tfvars

# Check for drift
terraform plan -var-file=dev.tfvars -detailed-exitcode

# Compare provider versions
grep "azurerm" .terraform.lock.hcl
```

### Issue: Can't Access Old State Files

**Solution**: Copy state files before migration
```bash
# List all state files
az storage blob list \
  --container-name tfstate \
  --account-name <old-storage-account> \
  --output table

# Download all
az storage blob download-batch \
  --source tfstate \
  --destination ./state-backup \
  --account-name <old-storage-account>
```

### Issue: Service Principal Permission Denied

**Solution**: Grant required permissions
```bash
# Check current permissions
az role assignment list --assignee <sp-app-id>

# Grant Contributor
az role assignment create \
  --assignee <sp-app-id> \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>

# Grant User Access Administrator (for RBAC)
az role assignment create \
  --assignee <sp-app-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<sub-id>
```

---

## 📚 Post-Migration Checklist

After migration is complete:

### Immediate (Day 1)
- [ ] All environments deployed via pipeline
- [ ] All manual deployments disabled
- [ ] Team trained on new process
- [ ] Documentation updated
- [ ] Monitoring configured

### Short-term (Week 1)
- [ ] Review all pipeline runs
- [ ] Address any issues
- [ ] Optimize pipeline performance
- [ ] Gather team feedback
- [ ] Update procedures based on learnings

### Long-term (Month 1)
- [ ] Pipeline success rate > 95%
- [ ] Average deployment time documented
- [ ] Zero manual deployments
- [ ] All approvals functioning
- [ ] Security scans passing
- [ ] Team comfortable with process

---

## 🎉 Success!

You've successfully migrated to Azure DevOps pipelines! Your infrastructure is now:

- ✅ Automated and consistent
- ✅ Secure with no hardcoded credentials
- ✅ Auditable with full deployment history
- ✅ Governed with approval workflows
- ✅ Scalable for team growth

## 📞 Support During Migration

If you encounter issues:

1. Check migration logs and backups
2. Review pipeline execution logs
3. Consult troubleshooting section
4. Rollback if necessary (use backup state)
5. Contact DevOps team for assistance

## 📝 Lessons Learned

Document your migration experience:

- What went well?
- What challenges did you face?
- What would you do differently?
- How long did each phase take?
- Any recommendations for others?

This helps future migrations and continuous improvement.

---

**Remember**: Take your time, test thoroughly, and keep good backups. A careful migration is a successful migration! 🚀

