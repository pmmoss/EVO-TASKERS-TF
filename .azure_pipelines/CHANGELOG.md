# Pipeline Changelog

## v2.1.1 - 2024-10-20

### 🐛 Bug Fix: Stale Plan Handling

**Issue**: "Saved plan is stale" error when state changes between plan and apply

**Improvements**:
- Better error messages in apply stage
- Troubleshooting guide for stale plans
- Environment exclusive lock recommendation
- Best practices for preventing concurrent runs

**Root Cause**: State modified by concurrent pipelines or manual operations

**Prevention**:
- Enable exclusive lock on environments
- Approve quickly after plan
- Avoid concurrent pipeline runs

**Files Changed**: 
- `templates/terraform-apply.yml`
- `.azure_pipelines/README.md`

---

## v2.1.0 - 2024-10-20

### ✨ New Feature: Multi-App Pipeline

**Added**: `multi-app-pipeline.yml` for deploying multiple applications

**Features**:
- Deploy multiple apps in one pipeline run
- Sequential or parallel deployment strategies
- Single approval for all apps
- Reuses all existing templates
- Combined security & cost analysis

**Use Cases**:
- Full environment deployment
- Coordinated releases
- Initial setup
- Disaster recovery

**Files Added**: `multi-app-pipeline.yml`

---

## v2.0.1 - 2024-10-20

### 🐛 Bug Fix: Security Scan Exit Codes

**Issue**: Checkov failing pipeline even with `failOnSecurityIssues: false`

**Fix**: Updated `security-scan.yml` to properly handle exit codes based on parameter

**Behavior**:
- `failOnSecurityIssues: false` → Warnings, pipeline continues ✅
- `failOnSecurityIssues: true` → Errors, pipeline fails ❌

**Files Changed**: `templates/security-scan.yml`

---

## v2.0.0 - 2024-10-20

### ✨ New Features

**Security Scanning**
- Checkov, tfsec, TFLint integration
- Configurable fail behavior
- Test results publishing

**Cost Analysis**
- Infracost integration
- HTML/JSON/text reports
- Monthly cost estimates

**Pipeline Improvements**
- Reusable templates
- Manual approval gate
- Parallel stage execution
- Optional security/cost stages

**Files Added**:
- `templates/security-scan.yml`
- `templates/cost-analysis.yml`
- `templates/setup-auth.yml`
- `templates/terraform-init.yml`
- `templates/terraform-plan.yml`
- `templates/terraform-apply.yml`
- `.azure_pipelines/README.md`

**Files Updated**:
- `main-pipeline.yml`
- `README.md`

---

## v1.0.0 - Previous

- Basic plan/apply workflow
- OIDC authentication
- Remote state management
- Multi-environment support

---

## Version Matrix

| Version | Date | Major Changes |
|---------|------|---------------|
| 2.1.1 | 2024-10-20 | Fix: Stale plan handling |
| 2.1.0 | 2024-10-20 | Feature: Multi-app pipeline |
| 2.0.1 | 2024-10-20 | Fix: Exit code handling |
| 2.0.0 | 2024-10-20 | Feature: Security & cost |
| 1.0.0 | Previous | Initial release |

---

## Upgrade Notes

### v2.0.0 → v2.0.1
✅ No action required - bug fix only
✅ Backward compatible

### v1.0 → v2.0
✅ Backward compatible - new features are optional
✅ To disable new features: Set `runSecurityScan: false` and `runCostAnalysis: false`

---

## Known Issues

None

---

## Roadmap

- [ ] Cost threshold enforcement
- [ ] Historical cost tracking
- [ ] PR comment integration
- [ ] Drift detection
- [ ] Automated remediation suggestions
