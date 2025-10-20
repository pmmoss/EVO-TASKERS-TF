# Azure DevOps Pipeline Documentation

This directory contains the Azure DevOps pipeline configuration for deploying Terraform infrastructure.

## 📁 Files Overview

### Main Pipeline
- **`main-pipeline.yml`** - Main pipeline orchestrator
  - Defines all pipeline stages and parameters
  - Calls reusable templates
  - Configures environments and triggers

### Reusable Templates

#### Core Templates
- **`templates/setup-auth.yml`** - Azure authentication setup
  - OIDC/Service Principal authentication
  - Sets ARM environment variables
  - Validates authentication

- **`templates/terraform-init.yml`** - Terraform initialization
  - Configures remote state backend
  - Initializes providers
  - Sets up working directory

- **`templates/terraform-plan.yml`** - Plan generation
  - Validates Terraform configuration
  - Generates execution plan
  - Archives and publishes plan artifacts

- **`templates/terraform-apply.yml`** - Apply execution
  - Applies approved plan
  - Shows deployment outputs
  - Handles ARM authentication

#### Security & Cost Templates
- **`templates/security-scan.yml`** - Security scanning
  - Installs: Checkov, tfsec, TFLint
  - Scans for security vulnerabilities
  - Publishes test results

- **`templates/cost-analysis.yml`** - Cost estimation
  - Installs Infracost
  - Generates cost breakdown
  - Creates HTML/JSON/text reports

### Documentation
- **`SECURITY-AND-COST-SETUP.md`** - Setup guide for security and cost features
- **`PIPELINE-FLOW.md`** - Visual pipeline flow and stage details
- **`README.md`** (this file) - Pipeline documentation overview

### Scripts (if present)
- **`scripts/`** - Helper scripts for setup and utilities

## 🚀 Quick Start

### Running the Pipeline

1. Navigate to **Pipelines** in Azure DevOps
2. Select **main-pipeline**
3. Click **Run pipeline**
4. Configure parameters:
   ```
   Environment: dev/qa/prod
   Project Name: evo-taskers
   Application Name: automateddatafeed
   Run Security Scan: ✓ (recommended)
   Run Cost Analysis: ✓ (recommended)
   Fail on Security Issues: ☐ (optional)
   ```
5. Click **Run**

### First-Time Setup

#### 1. Service Connection
Create a service connection in Azure DevOps:
```
Project Settings → Service connections → New service connection
Type: Azure Resource Manager
Authentication: Workload Identity Federation (OIDC)
Name: EVO-Taskers-Sandbox
```

#### 2. Variable Group
Create `terraform-backend` variable group:
```yaml
BACKEND_RESOURCE_GROUP_NAME: <rg-name>
BACKEND_STORAGE_ACCOUNT_NAME: <storage-account>
BACKEND_CONTAINER_NAME: <container>
INFRACOST_API_KEY: <optional-api-key>  # Secret variable
```

#### 3. Environments
Create environments for deployment approvals:
```
Environments → New environment
Name: evo-taskers-dev
Name: evo-taskers-qa
Name: evo-taskers-prod
```

## 🏗️ Pipeline Architecture

### Stage Flow
```
1. Plan (Required)
   ├── Install Terraform
   ├── Setup Authentication
   ├── Terraform Init
   ├── Terraform Validate
   └── Terraform Plan

2. Security Scan (Optional, Parallel)
   ├── Install Tools
   ├── Checkov Scan
   ├── tfsec Scan
   └── TFLint

3. Cost Analysis (Optional, Parallel)
   ├── Install Infracost
   ├── Generate Estimates
   └── Create Reports

4. Approval (Required if changes)
   └── Manual Validation

5. Apply (Required)
   ├── Download Plan
   ├── Setup Authentication
   └── Terraform Apply
```

## 🔧 Configuration

### Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | `dev` | Target environment (dev/qa/prod) |
| `projectName` | string | `evo-taskers` | Project name |
| `appName` | string | `automateddatafeed` | Application to deploy |
| `runSecurityScan` | boolean | `true` | Enable security scanning |
| `runCostAnalysis` | boolean | `true` | Enable cost analysis |
| `failOnSecurityIssues` | boolean | `false` | Fail pipeline on security findings |

### Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `BACKEND_RESOURCE_GROUP_NAME` | Variable group | State storage resource group |
| `BACKEND_STORAGE_ACCOUNT_NAME` | Variable group | State storage account |
| `BACKEND_CONTAINER_NAME` | Variable group | State blob container |
| `INFRACOST_API_KEY` | Variable group | Infracost API key (optional) |
| `workingDirectory` | Pipeline | Calculated app directory |
| `terraformVersion` | Pipeline | Terraform version to use |
| `serviceConnection` | Pipeline | Azure service connection name |

## 📊 Understanding Pipeline Outputs

### Artifacts

**terraform-plan** (after Plan stage)
- Terraform plan file
- Complete working directory
- Used by Apply stage

**cost-analysis-{env}** (after Cost Analysis)
- `infracost-report.txt` - Text format
- `infracost-report.html` - Interactive report
- `infracost-base.json` - JSON data

### Test Results

**Security Scan Results**
- Published as JUnit test results
- View in **Tests** tab
- Shows pass/fail by check

### Logs

**Plan Stage**
- Resource changes summary
- State file operations
- Validation results

**Security Scan**
- Detailed vulnerability findings
- Severity levels
- Remediation suggestions

**Cost Analysis**
- Monthly cost breakdown
- Cost per resource
- Comparison data

**Apply Stage**
- Resource creation/updates
- Terraform outputs
- Operation duration

## 🔒 Security Features

### Authentication
- **OIDC (Recommended)**: No secrets stored
- **Service Principal**: Fallback option
- Automatic credential rotation

### State Management
- Remote state in Azure Storage
- State locking enabled
- Encrypted at rest

### Scanning Tools

**Checkov**
- 1000+ security rules
- Compliance frameworks
- Azure best practices

**tfsec**
- Terraform-specific
- Fast scanning
- Clear remediation

**TFLint**
- Syntax errors
- Best practices
- Provider rules

## 💰 Cost Analysis Features

### Infracost Integration
- Real-time pricing data
- Monthly cost estimates
- Resource-level breakdown

### Reports Generated
- **Console**: Quick overview
- **HTML**: Interactive exploration
- **JSON**: Automation/reporting
- **Text**: Documentation

### Cost Insights
- Compare environments
- Identify expensive resources
- Track cost changes
- Budget planning

## 🛠️ Customization

### Adding New Applications

1. Create app directory:
   ```
   project/evo-taskers/<new-app>/
   ```

2. Add to pipeline parameters:
   ```yaml
   - name: appName
     values:
       - existing-app
       - new-app  # Add here
   ```

### Modifying Security Checks

Skip specific checks in `main-pipeline.yml`:
```yaml
- template: templates/security-scan.yml
  parameters:
    checkovSkipChecks: 'CKV_AZURE_1,CKV_AZURE_13'
```

### Custom Terraform Version

Change in `main-pipeline.yml`:
```yaml
variables:
  - name: terraformVersion
    value: '1.13.0'  # Update version
```

## 📚 Additional Resources

- [Security & Cost Setup Guide](SECURITY-AND-COST-SETUP.md)
- [Pipeline Flow Diagram](PIPELINE-FLOW.md)
- [Main README](../README.md)

### External Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Checkov Checks](https://www.checkov.io/5.Policy%20Index/terraform.html)
- [Infracost Documentation](https://www.infracost.io/docs/)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)

## 🆘 Troubleshooting

### Common Issues

**Authentication Failed**
```bash
Error: Failed to get existing workspaces
```
→ Check service connection configuration
→ Verify RBAC permissions on subscription

**State Lock**
```bash
Error: Error acquiring the state lock
```
→ Check for running pipelines
→ Force unlock if safe: `terraform force-unlock <id>`

**Security Scan Errors**
```bash
Error: Tool installation failed
```
→ Verify ubuntu-latest agent
→ Check internet connectivity

**Cost Analysis Warnings**
```bash
Warning: No Infracost API key
```
→ Add INFRACOST_API_KEY to variable group
→ Or ignore (still works without)

### Support

1. Check pipeline logs for detailed errors
2. Review test results for security findings
3. Examine artifacts for cost reports
4. Consult documentation links above

## 🔄 Version History

### v2.0 (Current)
- ✅ Added security scanning (Checkov, tfsec, TFLint)
- ✅ Added cost analysis (Infracost)
- ✅ Refactored into reusable templates
- ✅ Added manual approval gate
- ✅ Parallel stage execution

### v1.0
- ✅ Basic plan/apply workflow
- ✅ OIDC authentication
- ✅ Remote state management
- ✅ Multi-environment support

## 📝 Contributing

When modifying the pipeline:

1. **Test in dev first**: Always test changes in dev environment
2. **Update docs**: Keep documentation in sync
3. **Version templates**: Consider template versioning
4. **Validate YAML**: Use Azure DevOps YAML validator
5. **Review logs**: Check pipeline runs for warnings

## 📞 Contacts

For pipeline issues or questions:
- DevOps Team: [your-team]
- Security: [security-team]
- Cloud Ops: [cloud-team]

