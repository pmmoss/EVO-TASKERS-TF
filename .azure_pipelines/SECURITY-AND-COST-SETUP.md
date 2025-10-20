# Security Scanning and Cost Analysis Setup Guide

This guide explains how to set up and use the optional security scanning and cost analysis features in the Azure DevOps pipeline.

## Overview

The pipeline now includes two optional stages:
- **Security Scan**: Scans Terraform code for security vulnerabilities and misconfigurations
- **Cost Analysis**: Estimates monthly infrastructure costs

Both stages are **enabled by default** but can be disabled via pipeline parameters.

## Security Scanning

### Tools Used (All Free)

1. **Checkov** - Comprehensive IaC security scanner
   - Checks for 1000+ security and compliance issues
   - Supports Azure best practices
   - CIS benchmarks and compliance frameworks

2. **tfsec** - Terraform-specific security scanner
   - Fast, lightweight scanner
   - Azure-specific security checks
   - Integration with IDE and CI/CD

3. **TFLint** - Terraform linter
   - Catches errors before deployment
   - Enforces best practices
   - Provider-specific rules

### Setup

No additional setup required! Tools are automatically installed during the pipeline run.

### Configuration

#### Disable Security Scanning

When running the pipeline, set the parameter:
```
Run Security Scan: false
```

#### Fail Pipeline on Security Issues

By default, security issues are reported as **warnings only** and the pipeline continues:
```
Fail Pipeline on Security Issues: false  (default)
→ Security issues logged as warnings
→ Pipeline continues to approval stage
→ Review findings during manual approval
```

To fail the pipeline immediately when security issues are found:
```
Fail Pipeline on Security Issues: true
→ Security issues logged as errors
→ Pipeline stops immediately
→ No approval stage reached
```

**Recommendation**: Use `false` for dev/qa, `true` for production.

#### Skip Specific Checks

To skip certain Checkov checks, modify the template call in `main-pipeline.yml`:

```yaml
- template: templates/security-scan.yml
  parameters:
    workingDirectory: '$(workingDirectory)'
    failOnSecurityIssues: ${{ parameters.failOnSecurityIssues }}
    checkovSkipChecks: 'CKV_AZURE_1,CKV_AZURE_2'  # Add checks to skip
```

### Review Results

Security scan results are published as test results in the pipeline. View them in:
1. Pipeline run summary
2. **Tests** tab (JUnit format)
3. Pipeline logs for detailed output

### Common Security Findings

#### Azure Storage Account

- **Public access**: Ensure storage accounts are not publicly accessible
- **HTTPS only**: Enable secure transfer requirement
- **Minimum TLS version**: Use TLS 1.2 or higher

#### Key Vault

- **Soft delete**: Enable soft delete protection
- **Purge protection**: Enable for production environments
- **Network rules**: Restrict access via private endpoints

#### Function Apps

- **HTTPS only**: Enforce HTTPS
- **Managed identity**: Use managed identity for authentication
- **Minimum TLS version**: Use TLS 1.2 or higher

## Cost Analysis

### Tool Used

**Infracost** - Cloud cost estimates for Terraform
- Shows cost breakdown by resource
- Compares costs across environments
- Identifies cost optimization opportunities
- Free for individual use

### Setup

#### Step 1: Get Infracost API Key (Free)

1. Go to https://www.infracost.io/
2. Click "Get Started Free"
3. Sign up (GitHub, GitLab, or email)
4. Copy your API key from the dashboard

#### Step 2: Add API Key to Azure DevOps

1. Navigate to your Azure DevOps project
2. Go to **Pipelines** → **Library**
3. Open the `terraform-backend` variable group
4. Click **+ Add**
5. Add variable:
   - Name: `INFRACOST_API_KEY`
   - Value: `your-api-key-here`
   - **Important**: Click the lock icon to make it a secret variable
6. Save the variable group

### Configuration

#### Disable Cost Analysis

When running the pipeline, set the parameter:
```
Run Cost Analysis: false
```

#### Without API Key

The cost analysis will still work without an API key using Infracost's default free tier, but you'll see a warning. You can register during the pipeline run.

### Review Results

Cost analysis results are available in:
1. **Pipeline logs** - Text-based cost breakdown
2. **Artifacts** - Download detailed reports:
   - `infracost-report.txt` - Text format
   - `infracost-report.html` - Interactive HTML report
   - `infracost-base.json` - JSON for programmatic use

### Understanding Cost Reports

#### Example Output

```
Project: evo-taskers-automateddatafeed-dev

Name                                    Monthly Qty  Unit    Monthly Cost

azurerm_app_service_plan.main
 ├─ Instance usage (P1v3)                      730  hours         $146.00

azurerm_storage_account.main
 ├─ Capacity (Standard, Hot, LRS)              100  GB              $2.10
 ├─ Write operations                        10,000  10k ops         $0.11
 ├─ Read operations                        100,000  10k ops         $0.04

OVERALL TOTAL                                                     $148.25
```

#### Key Metrics

- **Monthly Cost**: Estimated recurring monthly cost
- **Resource Breakdown**: Cost per Azure resource
- **Environment Comparison**: Compare dev vs QA vs prod costs

### Cost Optimization Tips

1. **Right-size App Service Plans**: Don't use P2v3 for dev environments
2. **Use consumption tier for dev**: Consider Function App consumption plan for dev
3. **Storage tiers**: Use Cool or Archive for infrequent access data
4. **Reserved instances**: For production, consider Azure reservations
5. **Scale down dev/QA**: Shut down non-prod resources after hours

## Pipeline Workflow

With security and cost analysis enabled, the pipeline flow is:

```
1. Plan
   └─ Terraform plan runs
   
2. Security Scan (parallel with Cost Analysis)
   └─ Checkov, tfsec, TFLint run
   
3. Cost Analysis (parallel with Security Scan)
   └─ Infracost generates estimates
   
4. Approval
   └─ Manual review of plan + security + cost
   
5. Apply
   └─ Terraform apply runs
```

## Best Practices

### Security

1. **Review all findings**: Don't ignore security warnings
2. **Fix critical issues**: Address high-severity findings immediately
3. **Document exceptions**: If skipping checks, document why
4. **Test in dev first**: Catch issues early in lower environments
5. **Enable failure for prod**: Set `failOnSecurityIssues: true` for production

### Cost

1. **Set budgets**: Define acceptable cost thresholds per environment
2. **Review before approval**: Check cost estimates during approval stage
3. **Compare environments**: Ensure dev isn't more expensive than it should be
4. **Track trends**: Monitor cost changes over time
5. **Optimize regularly**: Review and optimize based on reports

## Troubleshooting

### Security Scan Issues

**"Checkov found security issues" - Pipeline failing unexpectedly**

This is expected behavior! The behavior depends on the `failOnSecurityIssues` parameter:

```yaml
# Default behavior (recommended for dev/qa):
failOnSecurityIssues: false
→ Checkov findings show as WARNINGS
→ Pipeline continues to approval
→ Review findings before approving

# Strict mode (recommended for prod):
failOnSecurityIssues: true
→ Checkov findings show as ERRORS
→ Pipeline fails immediately
→ Must fix issues before re-running
```

**Tools fail to install**
```bash
# Check if using ubuntu-latest pool
pool:
  vmImage: 'ubuntu-latest'
```

**Too many false positives**
```yaml
# Skip specific checks in the template parameters
checkovSkipChecks: 'CKV_AZURE_1,CKV_AZURE_13'
```

**Pipeline fails even with failOnSecurityIssues=false**

Check the security scan logs - the scripts now explicitly handle the parameter:
- Should see: "Checkov found security issues - continuing due to failOnSecurityIssues=false"
- If not, verify you're using the latest version of `security-scan.yml` template

### Cost Analysis Issues

**"No Infracost API key provided"**
- This is just a warning. Cost analysis will still work.
- To remove warning, add INFRACOST_API_KEY to variable group.

**Costs seem wrong**
- Verify the correct tfvars file is being used
- Check that all resources have pricing information
- Some resources may show $0 if pricing isn't available yet

**API rate limit**
- Free tier has usage limits
- Upgrade to paid plan or reduce analysis frequency

## Disabling Features

### Temporarily Disable

Use pipeline parameters when running:
- Uncheck "Run Security Scan"
- Uncheck "Run Cost Analysis"

### Permanently Disable

Edit `main-pipeline.yml` and change defaults:

```yaml
parameters:
  - name: runSecurityScan
    default: false  # Change to false
  
  - name: runCostAnalysis
    default: false  # Change to false
```

## Resources

- **Checkov**: https://www.checkov.io/
- **tfsec**: https://aquasecurity.github.io/tfsec/
- **TFLint**: https://github.com/terraform-linters/tflint
- **Infracost**: https://www.infracost.io/docs/

## Support

For issues or questions:
1. Check the pipeline logs for detailed error messages
2. Review the test results and artifacts
3. Consult the tool documentation links above

