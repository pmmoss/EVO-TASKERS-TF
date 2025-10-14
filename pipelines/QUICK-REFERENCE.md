# Azure DevOps Pipeline - Quick Reference Card

## 🚀 Common Operations

### Deploying Changes

```bash
# 1. Create feature branch
git checkout -b feature/my-change

# 2. Make your Terraform changes
# Edit .tf files in project/evo-taskers/<app>/

# 3. Commit and push
git add .
git commit -m "feat: describe your change"
git push origin feature/my-change

# 4. Create Pull Request in Azure DevOps
# - Pipeline will automatically run plan
# - Review the plan output
# - Get approval from team

# 5. Merge to develop (deploys to Dev/QA)
# - Pipeline runs automatically
# - Dev deploys first
# - QA deploys after Dev succeeds

# 6. Merge to main (deploys to Prod)
# - Create PR from develop to main
# - Pipeline runs plan on Prod
# - Approve deployment
# - Prod deploys
```

### Deployment Flow

```
feature/* → develop → Dev/QA (automatic)
                ↓
           main → Production (requires approval)
```

## 🔍 Checking Pipeline Status

### Via Azure DevOps UI

1. Navigate to **Pipelines** → **Pipelines**
2. Click on pipeline name
3. View recent runs
4. Click run to see details

### Via Azure CLI

```bash
# List recent runs
az pipelines runs list --top 10 --output table

# Show specific run
az pipelines runs show --id <run-id>

# Follow a running pipeline
az pipelines runs show --id <run-id> --open
```

## 📥 Downloading Artifacts

### Terraform Plan

```bash
# Download plan from a specific run
az pipelines runs artifact download \
  --artifact-name tfplan-dev \
  --run-id <run-id> \
  --path ./downloads

# View the plan
cd downloads
terraform show tfplan
```

### Terraform Outputs

```bash
# Download outputs
az pipelines runs artifact download \
  --artifact-name terraform-outputs-dev \
  --run-id <run-id> \
  --path ./downloads

# View outputs
cat downloads/terraform-outputs.json | jq
```

## 🎯 Manual Pipeline Triggers

### Trigger Specific Pipeline

```bash
# Trigger landing zone pipeline
az pipelines run \
  --name "Landing Zone - Terraform" \
  --branch develop

# Trigger with parameters
az pipelines run \
  --name "Applications - Terraform" \
  --branch main \
  --parameters deployAutomatedDataFeed=true deployDashboard=false
```

### Via UI

1. Go to **Pipelines** → **Pipelines**
2. Select pipeline
3. Click **Run pipeline**
4. Select branch
5. Set parameters (if any)
6. Click **Run**

## ⏸️ Managing Running Pipelines

### Cancel a Pipeline

```bash
# Via CLI
az pipelines build cancel --id <build-id>

# Via UI
# Go to running pipeline → Click "Cancel"
```

### Retry a Failed Stage

```bash
# Via UI only:
# 1. Go to failed pipeline run
# 2. Click on failed stage
# 3. Click "Retry stage"
```

## ✅ Approving Production Deployments

### When You Receive Approval Request

1. Click email notification link (or go to pipeline)
2. Review the pipeline run
3. Check the **Terraform plan** output
4. Verify changes are expected
5. Click **Approve** or **Reject**
6. Add comment explaining decision

### What to Check Before Approving

- [ ] Plan output shows expected changes only
- [ ] No unexpected resource deletions
- [ ] Resource names follow naming convention
- [ ] No security scan failures
- [ ] Previous stages (Dev/QA) succeeded
- [ ] Change has been tested in lower environments

## 🔧 Troubleshooting

### Pipeline Stuck at Init

```bash
# Check state lock
az storage blob lease list \
  --container-name tfstate \
  --account-name <storage-account>

# If stuck, contact DevOps team to break lease
```

### Permission Denied

```bash
# Check service connection
# Go to: Project Settings → Service connections
# Verify service connection exists and is authorized

# Check variable group access
# Go to: Pipelines → Library
# Verify pipeline has access to variable group
```

### Plan Shows Unexpected Changes

```bash
# Check for drift
terraform refresh -var-file=dev.tfvars

# Compare with known state
terraform state list
```

### Security Scan Failures

```bash
# Download security results
az pipelines runs artifact download \
  --artifact-name security-results \
  --run-id <run-id>

# Review findings
# Fix issues in Terraform code
# Or add skip annotation if false positive
```

## 📋 Environment Details

### Service Connections

| Environment | Service Connection Name |
|------------|------------------------|
| Development | `Azure-Dev-ServiceConnection` |
| QA | `Azure-QA-ServiceConnection` |
| Production | `Azure-Prod-ServiceConnection` |

### Variable Groups

| Group Name | Purpose |
|-----------|---------|
| `terraform-backend` | Backend storage configuration |
| `evo-taskers-common` | Common infrastructure vars |
| `evo-taskers-apps` | Application workload vars |

### Pipelines

| Pipeline | Purpose |
|---------|---------|
| Landing Zone - Terraform | Deploy common infrastructure |
| Applications - Terraform | Deploy application workloads |

## 🗺️ State File Locations

### Backend Storage

```
Storage Account: stterraformstate<id>
Container: tfstate
Resource Group: rg-terraform-state

State Files:
├── landing-zone/evo-taskers-common-dev.tfstate
├── landing-zone/evo-taskers-common-qa.tfstate
├── landing-zone/evo-taskers-common-prod.tfstate
├── landing-zone/evo-taskers-automateddatafeed.tfstateenv:dev
├── landing-zone/evo-taskers-automateddatafeed.tfstateenv:qa
└── landing-zone/evo-taskers-automateddatafeed.tfstateenv:prod
```

### Viewing State

```bash
# List state files
az storage blob list \
  --container-name tfstate \
  --account-name <storage-account> \
  --output table

# Download state file
az storage blob download \
  --container-name tfstate \
  --name <blob-name> \
  --file state.json \
  --account-name <storage-account>

# View state
terraform state list -state=state.json
```

## 🔄 Common Workflows

### Adding New Application

1. Copy `pipelines/examples/single-app-pipeline.yml`
2. Customize for your application
3. Create environments in Azure DevOps
4. Add pipeline to Azure DevOps
5. Deploy!

### Updating Module

1. Make changes to module in `modules/`
2. Test locally first
3. Create PR with changes
4. Pipeline validates changes
5. Merge to deploy

### Emergency Rollback

```bash
# Option 1: Revert commit and redeploy
git revert <commit-hash>
git push

# Option 2: Restore state (last resort)
# Contact DevOps team for state restoration
```

## 📞 Getting Help

### During Business Hours
1. Check pipeline logs first
2. Search documentation
3. Contact DevOps team

### Emergency (Production Down)
1. Contact on-call DevOps engineer
2. Follow incident response procedures
3. Document issue in ticket

### Documentation Links

- Full Documentation: `pipelines/README.md`
- Setup Guide: `pipelines/setup/COMPLETE-SETUP-GUIDE.md`
- Migration Guide: `pipelines/MIGRATION-GUIDE.md`
- Troubleshooting: `pipelines/README.md#troubleshooting`

## 🎓 Learning Resources

### New to Terraform Pipelines?

1. Read `PIPELINE-SETUP-SUMMARY.md`
2. Review `pipelines/README.md`
3. Watch a pipeline run end-to-end
4. Try deploying to Dev environment
5. Practice approving a deployment

### Common Commands Cheatsheet

```bash
# List pipelines
az pipelines list --output table

# List recent runs
az pipelines runs list --top 5 --output table

# Show run details
az pipelines runs show --id <run-id>

# Download artifacts
az pipelines runs artifact download --run-id <run-id> --artifact-name <name>

# Trigger pipeline
az pipelines run --name <pipeline-name> --branch <branch>

# Cancel pipeline
az pipelines build cancel --id <build-id>
```

## ⚡ Pro Tips

1. **Always review plan output** before approving
2. **Test in Dev first** before promoting to QA/Prod
3. **Use descriptive commit messages** for audit trail
4. **Check security scan results** in pipeline
5. **Keep documentation updated** with changes
6. **Monitor pipeline runs** regularly
7. **Backup before major changes** (automatic with state versioning)
8. **Use feature branches** for all changes
9. **Link work items** to deployments
10. **Communicate** with team about production changes

## 🔐 Security Reminders

- ❌ Never commit secrets or credentials
- ❌ Never hardcode subscription IDs
- ❌ Never share service principal credentials
- ❌ Never bypass approvals for production
- ✅ Always use service connections
- ✅ Always use variable groups for config
- ✅ Always review security scan results
- ✅ Always approve with justification

---

## Quick Reference Table

| Task | Command/Action |
|------|----------------|
| Deploy to Dev | Merge to `develop` branch |
| Deploy to Prod | Merge to `main` branch (requires approval) |
| Check pipeline status | Pipelines → Pipelines → Select pipeline |
| Approve deployment | Click email link or go to pipeline |
| Cancel running pipeline | Pipeline → Cancel or `az pipelines build cancel` |
| View plan output | Pipeline → Stage → Terraform Plan step |
| Download artifacts | `az pipelines runs artifact download` |
| Trigger manual run | Pipelines → Run pipeline or `az pipelines run` |
| Check state files | `az storage blob list --container-name tfstate` |
| Get help | Check docs or contact DevOps team |

---

**Keep this reference handy for daily pipeline operations!** 📌

