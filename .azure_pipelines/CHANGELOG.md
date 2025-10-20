# Pipeline Changelog

## 2024-10-20 - Security Scan Fix

### Issue
Checkov was failing the pipeline even when `failOnSecurityIssues` was set to `false`.

### Root Cause
The bash scripts in `security-scan.yml` were not properly handling the exit codes. When security tools found issues, they exited with non-zero codes which caused the task to fail, regardless of the `failOnSecurityIssues` parameter value.

### Fix Applied

Updated `templates/security-scan.yml` to properly handle exit codes:

**Checkov Scan:**
```bash
# Before (INCORRECT):
checkov -d . ... || EXIT_CODE=$?
if [ ${EXIT_CODE:-0} -ne 0 ]; then
  echo "##[warning]Checkov found security issues"
  exit ${EXIT_CODE}  # Always exits with error!
fi

# After (CORRECT):
set +e
checkov -d . ...
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
  if [ "${{ parameters.failOnSecurityIssues }}" == "True" ]; then
    echo "##[error]Checkov found security issues - failing pipeline"
    exit $EXIT_CODE
  else
    echo "##[warning]Checkov found security issues - continuing..."
    exit 0  # Exit successfully to continue pipeline
  fi
fi
```

**tfsec Scan:**
Similar fix applied for consistent behavior.

**TFLint:**
Updated to always exit 0 (informational only).

### Behavior Now

#### With `failOnSecurityIssues: false` (Default)
- ✅ Security findings logged as **WARNINGS**
- ✅ Pipeline **continues** to approval stage
- ✅ Reviewer can see findings and approve/reject
- ✅ Best for dev/qa environments

#### With `failOnSecurityIssues: true`
- ❌ Security findings logged as **ERRORS**
- ❌ Pipeline **fails immediately**
- ❌ Must fix issues before re-running
- ✅ Best for production environments

### Testing
Test the fix by:
1. Run pipeline with security issues present
2. Set `failOnSecurityIssues: false`
3. Verify pipeline continues with warnings
4. Check logs for: "Checkov found security issues - continuing due to failOnSecurityIssues=false"

### Documentation Updated
- `SECURITY-AND-COST-SETUP.md` - Added troubleshooting section
- `SECURITY-AND-COST-SETUP.md` - Clarified behavior with examples

---

## 2024-10-20 - Initial Release

### Features Added

#### Security Scanning
- **Checkov** integration for comprehensive IaC security
- **tfsec** for Terraform-specific checks
- **TFLint** for best practices and linting
- Configurable fail behavior
- Test results publishing

#### Cost Analysis
- **Infracost** integration
- Monthly cost estimates
- Multiple report formats (HTML, JSON, text)
- Resource-level breakdown

#### Pipeline Enhancements
- Reusable template architecture
- Manual approval gate
- Parallel stage execution
- Optional security/cost stages
- OIDC authentication

#### Documentation
- Comprehensive setup guide
- Pipeline flow diagram
- Quick reference card
- Troubleshooting guide

### Files Created
- `templates/security-scan.yml`
- `templates/cost-analysis.yml`
- `templates/setup-auth.yml`
- `templates/terraform-init.yml`
- `templates/terraform-plan.yml`
- `templates/terraform-apply.yml`
- `SECURITY-AND-COST-SETUP.md`
- `PIPELINE-FLOW.md`
- `QUICK-REFERENCE.md`
- `.azure_pipelines/README.md`

### Files Updated
- `main-pipeline.yml` - Added security/cost stages
- `README.md` - Updated documentation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.1 | 2024-10-20 | Fix: Checkov exit code handling |
| 2.0.0 | 2024-10-20 | Feature: Security scanning & cost analysis |
| 1.0.0 | Previous | Initial plan/apply workflow |

---

## Upgrade Notes

### From v2.0.0 to v2.0.1

**Action Required:** None - this is a bug fix release.

**What Changed:**
- Security scan tasks now properly respect the `failOnSecurityIssues` parameter
- Exit code handling improved in all security scan tasks

**Breaking Changes:** None

**Backward Compatible:** Yes

### From v1.0 to v2.0

**Action Required:** Optional

**What's New:**
- Security scanning (optional, can be disabled)
- Cost analysis (optional, can be disabled)
- Manual approval gate

**Breaking Changes:** None - new features are additive

**To Enable New Features:**
1. Run pipeline with default parameters (security/cost enabled by default)
2. Optionally: Add `INFRACOST_API_KEY` to variable group
3. Review security findings in test results
4. Review cost estimates in artifacts

**To Maintain Old Behavior:**
Set these parameters when running pipeline:
```yaml
Run Security Scan: false
Run Cost Analysis: false
```

---

## Known Issues

### Current Issues
None

### Resolved Issues
- ✅ **v2.0.1**: Checkov failing pipeline with `failOnSecurityIssues: false`
- ✅ **v2.0.0**: Initial release - no prior issues

---

## Roadmap

### Planned Features
- [ ] Cost threshold enforcement
- [ ] Security baseline comparison
- [ ] Automated issue creation for findings
- [ ] Historical cost tracking
- [ ] PR comments with security/cost info
- [ ] Custom security policy packs
- [ ] Integration with Azure Policy

### Under Consideration
- [ ] Additional security scanners (Terrascan, Snyk)
- [ ] Cost optimization recommendations
- [ ] Drift detection stage
- [ ] Automated remediation suggestions
- [ ] Slack/Teams notifications

---

## Contributing

When making changes to the pipeline:

1. **Update this changelog** with your changes
2. **Bump version** in the version history table
3. **Test thoroughly** in dev environment first
4. **Update documentation** as needed
5. **Note breaking changes** if any

### Version Numbering

We use semantic versioning:
- **Major (X.0.0)**: Breaking changes
- **Minor (x.X.0)**: New features, backward compatible
- **Patch (x.x.X)**: Bug fixes, backward compatible

