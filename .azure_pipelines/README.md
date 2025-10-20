# Azure DevOps Pipeline Documentation

## Quick Start

### Running a Single-App Pipeline

1. **Pipelines** → **main-pipeline** → **Run pipeline**
2. Select parameters:
   - Environment: `dev` / `qa` / `prod`
   - Application: Choose from dropdown
   - Security Scan: ✓ (recommended)
   - Cost Analysis: ✓ (recommended)
3. Review plan → Approve → Deploy

### Running Multi-App Pipeline

1. **Pipelines** → **multi-app-pipeline** → **Run pipeline**
2. Select parameters:
   - Environment: `dev` / `qa` / `prod`
   - Applications: `common,automateddatafeed,dashboard` (comma-separated)
   - Deployment Strategy: `sequential` or `parallel`
   - Security Scan: ✓
   - Cost Analysis: ✓
3. Review all plans → Approve once → Deploy all apps

### First-Time Setup

**1. Service Connection**
```
Project Settings → Service connections → New
Type: Azure Resource Manager (OIDC)
Name: EVO-Taskers-Sandbox
```

**2. Variable Group: `terraform-backend`**
```yaml
BACKEND_RESOURCE_GROUP_NAME: <your-rg>
BACKEND_STORAGE_ACCOUNT_NAME: <your-sa>
BACKEND_CONTAINER_NAME: <your-container>
INFRACOST_API_KEY: <optional> # Secret variable, get free at infracost.io
```

**3. Environments** (for approvals and concurrency control)
```
Environments → New: evo-taskers-dev, evo-taskers-qa, evo-taskers-prod

For each environment, configure:
- Approvals: Add approvers (prod should require approval)
- Deployment history: Enable for audit trail
- Exclusive lock: ✓ (IMPORTANT - prevents concurrent deployments)
```

**Why Exclusive Lock?**
Prevents "stale plan" errors by ensuring only one deployment runs at a time.

## Pipeline Stages

```
Plan (2-3 min)
  ↓
Security Scan + Cost Analysis (parallel, 1-2 min each) [optional]
  ↓
Manual Approval (human review)
  ↓
Apply (3-10 min)
```

### Stage Details

| Stage | Purpose | Can Fail? | Optional? |
|-------|---------|-----------|-----------|
| **Plan** | Generate Terraform plan | Yes | No |
| **Security Scan** | Checkov, tfsec, TFLint | Configurable | Yes |
| **Cost Analysis** | Infracost estimates | No | Yes |
| **Approval** | Manual review gate | Yes | No* |
| **Apply** | Deploy changes | Yes | No |

\* Only runs if there are changes to apply

## Pipelines

### main-pipeline.yml
**Single application deployment**
- Deploy one app at a time
- Full control per application
- Best for individual app updates

### multi-app-pipeline.yml  
**Multiple application deployment**
- Deploy multiple apps in one run
- Sequential or parallel deployment
- Single approval for all apps
- Best for coordinated releases

## Templates

Located in `templates/` directory (shared by both pipelines):

- **`setup-auth.yml`** - Azure OIDC/Service Principal auth
- **`terraform-init.yml`** - Backend initialization
- **`terraform-plan.yml`** - Validation and planning
- **`terraform-apply.yml`** - Apply and outputs
- **`security-scan.yml`** - Security scanning tools
- **`cost-analysis.yml`** - Cost estimation

## Security Scanning

### Tools (all free)
- **Checkov**: 1000+ security checks, compliance frameworks
- **tfsec**: Terraform-specific security rules
- **TFLint**: Best practices and linting

### Behavior

**Default (`failOnSecurityIssues: false`)**
- Issues logged as warnings
- Pipeline continues
- Review during approval
- ✅ Recommended for dev/qa

**Strict (`failOnSecurityIssues: true`)**
- Issues logged as errors
- Pipeline fails immediately
- Must fix before re-running
- ✅ Recommended for production

### Skip Specific Checks

Edit `main-pipeline.yml` template call:
```yaml
- template: templates/security-scan.yml
  parameters:
    checkovSkipChecks: 'CKV_AZURE_1,CKV_AZURE_13'
```

### View Results
- **Tests** tab in pipeline run
- Pipeline logs for details

## Cost Analysis

### Setup
1. Sign up free at https://www.infracost.io/
2. Copy API key
3. Add to `terraform-backend` variable group as `INFRACOST_API_KEY` (secret)

Works without API key but shows a warning.

### Reports Generated
- **Console**: Quick cost breakdown
- **HTML**: Interactive report (download from artifacts)
- **JSON**: For automation
- **Text**: Documentation

### View Results
**Pipeline Run → Artifacts → `cost-analysis-{env}`**

## Configuration

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environment` | `dev` | Target environment |
| `projectName` | `evo-taskers` | Project name |
| `appName` | `automateddatafeed` | Application to deploy |
| `runSecurityScan` | `true` | Enable security scanning |
| `runCostAnalysis` | `true` | Enable cost analysis |
| `failOnSecurityIssues` | `false` | Fail on security findings |

### Variables

All in `terraform-backend` variable group:
- `BACKEND_RESOURCE_GROUP_NAME` - Required
- `BACKEND_STORAGE_ACCOUNT_NAME` - Required
- `BACKEND_CONTAINER_NAME` - Required
- `INFRACOST_API_KEY` - Optional

### Customization

**Change Terraform version:**
```yaml
# main-pipeline.yml
variables:
  - name: terraformVersion
    value: '1.13.0'  # Update here
```

**Add new application:**
```yaml
# main-pipeline.yml
parameters:
  - name: appName
    values:
      - existing-app
      - new-app  # Add here
```

## Multi-App Deployment

### When to Use

**Use Multi-App Pipeline when:**
- Deploying full environment (common + apps)
- Coordinated release across apps
- Initial environment setup
- Disaster recovery

**Use Single-App Pipeline when:**
- Updating one specific app
- Testing changes to one app
- Hotfixes
- Frequent iterations

### Deployment Strategies

**Sequential** (default)
```
common → automateddatafeed → dashboard → ...
```
- Apps deploy one after another
- Dependencies handled in order
- Safer, easier to debug
- Takes longer

**Parallel**
```
common + automateddatafeed + dashboard (simultaneously)
```
- All apps deploy at once
- Faster deployment
- Requires apps to be independent
- Harder to debug failures

### Example: Full Stack Deployment

```yaml
Environment: dev
Applications: common,automateddatafeed,autoopenshorex,dashboard,dashboardfrontend
Strategy: sequential
```

This deploys all apps in order with one approval.

## Common Scenarios

### Fast Dev Iteration (Single App)
```yaml
Pipeline: main-pipeline
Run Security Scan: ☐
Run Cost Analysis: ☐
```

### Standard Deployment (Single App)
```yaml
Pipeline: main-pipeline
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ☐
```

### Production Deployment (Single App)
```yaml
Pipeline: main-pipeline
Environment: prod
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ✓
```

### Full Environment Deployment (Multi-App)
```yaml
Pipeline: multi-app-pipeline
Environment: dev
Applications: common,app1,app2,app3
Strategy: sequential
```

## Troubleshooting

### Stale Plan Error

**Error**: `Saved plan is stale - state was changed by another operation`

This happens when the Terraform state changes between Plan and Apply stages.

**Common Causes:**
- Another pipeline running simultaneously
- Manual terraform operations during pipeline run
- Multiple people deploying at the same time
- Long delay between approval and apply

**Solutions:**

**Immediate Fix:**
1. Cancel the current pipeline run
2. Ensure no other pipelines are running
3. Re-run the pipeline (generates fresh plan)

**Prevention:**
```yaml
# Use Azure DevOps environment approvals to prevent concurrent runs
environment: 'evo-taskers-dev'  # Already configured
```

**For Multi-App Pipelines:**
- Use sequential strategy (safer)
- Approve quickly after plan completes
- Deploy common infrastructure separately first

**Check for Concurrent Runs:**
```bash
# In Azure DevOps
Pipelines → Filter by "Running" → Cancel others
```

### Authentication Failed
- Check service connection configuration
- Verify RBAC permissions (Contributor on subscription)
- Check service principal hasn't expired

### State Lock Error
```bash
# Only if certain no other process is running
terraform force-unlock <lock-id>
```

**Prevention:**
- Don't run multiple pipelines for same app/environment simultaneously
- Environment protection rules help prevent this

### Security Scan Fails
- **With `failOnSecurityIssues: false`**: Should show warnings and continue
- Check logs for: "continuing due to failOnSecurityIssues=false"
- Verify using `ubuntu-latest` agent

### Cost Analysis Warning
"No Infracost API key provided" - This is fine, cost analysis still works.

### Pipeline Won't Start
- Check service connection exists
- Verify variable group `terraform-backend` exists
- Validate YAML syntax

### Multi-App Deployment Fails Partially

**Issue**: Some apps deployed, others failed

**Sequential Strategy:**
- Apps deploy in order
- Failure stops remaining apps
- Already-deployed apps are live
- Re-run pipeline will skip successfully deployed apps

**Parallel Strategy:**
- All apps deploy simultaneously
- Harder to debug which failed
- May have partial deployment
- Use sequential for easier recovery

## Best Practices

1. **Use the pipeline** - Don't deploy locally
2. **Enable exclusive locks** - Prevent concurrent deployments (see Environment setup)
3. **Approve quickly** - Minimize time between plan and apply to avoid stale plans
4. **Enable security for prod** - Set `failOnSecurityIssues: true`
5. **Review costs** - Check estimates before approval
6. **Test in dev first** - Always test changes in lower environments
7. **Check for running pipelines** - Before starting new deployment
8. **Use sequential for multi-app** - Safer than parallel for coordinated deploys
9. **Document skipped checks** - If skipping security checks, document why

## Quick Commands

### Local Development
```bash
# Plan locally
cd project/evo-taskers/automateddatafeed
terraform init -backend-config="key=landing-zone/evo-taskers-app-dev.tfstate" -reconfigure
terraform plan -var-file="dev.tfvars"

# Security scan locally
checkov -d .
tfsec .
tflint

# Cost estimate locally
infracost breakdown --path . --terraform-var-file=dev.tfvars
```

### View Pipeline Artifacts
```
Pipeline Run → Artifacts → Download
- terraform-plan
- cost-analysis-{env}/infracost-report.html
```

### Cancel Pipeline
```
Pipeline Run → ⋯ menu → Cancel
```

## Typical Timings

- **Minimal** (plan → approval → apply): 5-13 min
- **Full** (+ security + cost): 7-16 min
- **+ Approval time**: Variable (human-dependent)

## Resources

- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest
- **Checkov**: https://www.checkov.io/
- **tfsec**: https://aquasecurity.github.io/tfsec/
- **Infracost**: https://www.infracost.io/docs/
- **Changelog**: See [`CHANGELOG.md`](CHANGELOG.md) for version history

## Support

For issues:
1. Check pipeline logs
2. Review test results (for security)
3. Download artifacts (for costs)
4. Check CHANGELOG.md for known issues
