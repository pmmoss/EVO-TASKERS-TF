# Pipeline Quick Reference Card

## 🎯 Pipeline Parameters Cheat Sheet

### Running a Standard Deployment
```yaml
Environment: dev
Project Name: evo-taskers
Application Name: automateddatafeed
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ☐
```

### Quick Dev Deployment (Fast)
```yaml
Environment: dev
Run Security Scan: ☐  # Disabled for speed
Run Cost Analysis: ☐  # Disabled for speed
```

### Production Deployment (Strict)
```yaml
Environment: prod
Run Security Scan: ✓
Run Cost Analysis: ✓
Fail on Security Issues: ✓  # Block on security issues
```

## 🚀 One-Liners

### View Pipeline Status
```bash
# Azure DevOps URL format
https://dev.azure.com/{org}/{project}/_build
```

### Check Artifacts
```
Pipeline Run → Artifacts → Download
- terraform-plan
- cost-analysis-{env}
```

### View Security Results
```
Pipeline Run → Tests tab
Filter by: Security Scan Results
```

### Download Cost Report
```
Pipeline Run → Artifacts → cost-analysis-{env}
→ infracost-report.html
```

## 📋 Stage Status Codes

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ Succeeded | Stage passed | Review outputs |
| ⚠️ Succeeded with issues | Warnings present | Check logs |
| ❌ Failed | Stage failed | Review errors |
| ⏭️ Skipped | Conditional skip | Check dependencies |
| ⏸️ Waiting | Approval needed | Approve or reject |
| 🚫 Canceled | User canceled | Re-run if needed |

## 🔑 Required Permissions

### Service Principal (OIDC)
```
Subscription: Contributor
State Storage: Storage Blob Data Contributor
Key Vault: Key Vault Contributor (if used)
```

### Pipeline User
```
Azure DevOps: Build Administrator
Environments: Approver (for prod)
Variable Groups: Reader
```

## 🛠️ Common CLI Commands

### Local Terraform (for testing)
```bash
# Initialize
terraform init \
  -backend-config="key=landing-zone/evo-taskers-app-dev.tfstate" \
  -reconfigure

# Plan
terraform plan -var-file="dev.tfvars"

# Apply
terraform apply -var-file="dev.tfvars"
```

### Security Scanning (Local)
```bash
# Install tools
pip3 install checkov
brew install tfsec tflint  # macOS
# or use install scripts from template

# Run scans
checkov -d .
tfsec .
tflint
```

### Cost Analysis (Local)
```bash
# Install Infracost
brew install infracost  # macOS
# or use install script

# Generate estimate
infracost breakdown \
  --path . \
  --terraform-var-file=dev.tfvars
```

## 📊 Typical Pipeline Timings

| Stage | Duration | Notes |
|-------|----------|-------|
| Plan | 2-3 min | Depends on resources |
| Security Scan | 1-2 min | Parallel with Cost |
| Cost Analysis | 1 min | Parallel with Security |
| Approval | Variable | Human-dependent |
| Apply | 3-10 min | Depends on changes |
| **Total (all features)** | **7-16 min** | Plus approval time |

## 🚨 Emergency Procedures

### Cancel Running Pipeline
```
Pipeline Run → ... menu → Cancel
```

### Force Unlock State
```bash
# Get lock ID from error message
terraform force-unlock <lock-id>

# Only if you're CERTAIN no other process is running!
```

### Rollback Deployment
```
1. Revert code to previous commit
2. Run pipeline with reverted code
3. Or: manually fix and re-deploy
```

### Skip Approval (Emergency)
```
Not recommended! Better to:
1. Cancel pipeline
2. Fix issue
3. Re-run with proper approval
```

## 💡 Pro Tips

### Speed Up Pipelines
- Skip scans for dev iterations
- Use incremental changes
- Cache provider plugins
- Run locally first to catch errors

### Security Best Practices
- Always scan before prod
- Review all high-severity findings
- Don't skip checks without documentation
- Enable `failOnSecurityIssues` for prod

### Cost Management
- Compare costs across environments
- Set up budget alerts
- Review reports regularly
- Right-size resources

### Debugging
- Check **Pipeline logs** first
- Review **Test results** for security
- Download **Artifacts** for details
- Enable verbose logging if needed

## 🎓 Learning Resources

### Terraform
```
https://developer.hashicorp.com/terraform/tutorials
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
```

### Security Tools
```
Checkov: https://www.checkov.io/
tfsec: https://aquasecurity.github.io/tfsec/
TFLint: https://github.com/terraform-linters/tflint
```

### Cost Analysis
```
Infracost: https://www.infracost.io/docs/
```

### Azure DevOps
```
https://docs.microsoft.com/en-us/azure/devops/pipelines/
```

## 📱 Mobile Quick Actions

### Approve from Mobile
```
1. Install Azure DevOps mobile app
2. Navigate to Pipelines
3. Find pending approval
4. Review and approve/reject
```

### Check Status from Mobile
```
1. Open Azure DevOps app
2. Pipelines → Recent runs
3. Tap run to view details
```

## 🔍 Quick Diagnostics

### Pipeline Won't Start
- [ ] Check service connection
- [ ] Verify variable group exists
- [ ] Check YAML syntax
- [ ] Review trigger configuration

### Plan Fails
- [ ] Authentication issues?
- [ ] State file locked?
- [ ] Backend configuration correct?
- [ ] Terraform syntax errors?

### Security Scan Fails
- [ ] Using ubuntu-latest agent?
- [ ] Internet connectivity OK?
- [ ] Check specific tool logs
- [ ] Review error messages

### Apply Fails
- [ ] Check Azure permissions
- [ ] Resource quota exceeded?
- [ ] Naming conflicts?
- [ ] Review Terraform errors

## 📞 Quick Contact

```
Pipeline Issues: DevOps Team
Security Findings: Security Team
Cost Questions: FinOps Team
Infrastructure: Cloud Ops Team
```

---

**Last Updated**: 2024
**Pipeline Version**: 2.0
**Terraform Version**: 1.13.0

