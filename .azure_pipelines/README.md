# Azure DevOps Pipeline Documentation

## Quick Start

### Running the Pipeline

1. **Pipelines** → **main-pipeline** → **Run pipeline**
2. Select parameters:
   - Environment: `dev` / `qa` / `prod`
   - Application: Choose from dropdown
   - Security Scan: ✓ (recommended)
   - Cost Analysis: ✓ (recommended)
3. Review plan → Approve → Deploy

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

**3. Environments** (for approvals)
```
Environments → New: evo-taskers-dev, evo-taskers-qa, evo-taskers-prod
```

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

## Templates

Located in `templates/` directory:

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

## Common Scenarios

### Fast Dev Iteration
```yaml
Run Security Scan: ☐
Run Cost Analysis: ☐
```

### Standard Deployment
```yaml
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ☐
```

### Production Deployment
```yaml
Environment: prod
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ✓
```

## Troubleshooting

### Authentication Failed
- Check service connection configuration
- Verify RBAC permissions (Contributor on subscription)
- Check service principal hasn't expired

### State Lock Error
```bash
# Only if certain no other process is running
terraform force-unlock <lock-id>
```

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

## Best Practices

1. **Use the pipeline** - Don't deploy locally
2. **Enable security for prod** - Set `failOnSecurityIssues: true`
3. **Review costs** - Check estimates before approval
4. **Test in dev first** - Always test changes in lower environments
5. **Document skipped checks** - If skipping security checks, document why

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
