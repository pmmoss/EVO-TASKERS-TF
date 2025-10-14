# Azure DevOps Pipelines - Documentation Index

## 📚 Start Here

New to this pipeline setup? Follow this path:

```
1. PIPELINE-SETUP-SUMMARY.md (5 min read)
   └─ Overview of what was created and why
   
2. setup/COMPLETE-SETUP-GUIDE.md (2-3 hours)
   └─ Step-by-step setup instructions
   
3. README.md (15 min read)
   └─ Comprehensive pipeline documentation
   
4. QUICK-REFERENCE.md (Keep handy)
   └─ Common operations and commands
```

## 🎯 By Role

### For Azure DevOps Administrators

**Setup & Configuration**
1. [COMPLETE-SETUP-GUIDE.md](./setup/COMPLETE-SETUP-GUIDE.md) - Full setup walkthrough
2. [create-service-connections.md](./setup/create-service-connections.md) - Service connections guide
3. [VARIABLE-GROUPS.md](./setup/VARIABLE-GROUPS.md) - Variable groups configuration
4. [create-variable-groups.sh](./setup/create-variable-groups.sh) - Automated setup script

**What to do:**
- [ ] Create Azure infrastructure (storage, service principals)
- [ ] Configure service connections
- [ ] Create variable groups
- [ ] Set up environments with approvals
- [ ] Create and configure pipelines
- [ ] Test deployment to Dev

### For Developers

**Daily Operations**
1. [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick command reference
2. [README.md](./README.md) - Full pipeline documentation
3. [examples/single-app-pipeline.yml](./examples/single-app-pipeline.yml) - Template for new apps

**What to do:**
- [ ] Understand the deployment flow
- [ ] Know how to trigger deployments
- [ ] Review plan outputs before merge
- [ ] Use feature branches for changes
- [ ] Follow the quick reference for common tasks

### For Team Leads

**Migration & Governance**
1. [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) - Migrating from manual to pipelines
2. [PIPELINE-SETUP-SUMMARY.md](../PIPELINE-SETUP-SUMMARY.md) - Executive summary
3. [README.md#security--best-practices](./README.md#security--best-practices) - Security guidelines

**What to do:**
- [ ] Plan migration timeline
- [ ] Coordinate team training
- [ ] Configure governance policies
- [ ] Set up monitoring and alerts
- [ ] Define approval workflows

### For DevOps Engineers

**Technical Deep Dive**
1. [templates/terraform-template.yml](./templates/terraform-template.yml) - Reusable template
2. [landing-zone-pipeline.yml](./landing-zone-pipeline.yml) - Infrastructure pipeline
3. [applications-pipeline.yml](./applications-pipeline.yml) - Application pipeline
4. [README.md#troubleshooting](./README.md#troubleshooting) - Troubleshooting guide

**What to do:**
- [ ] Understand template structure
- [ ] Customize pipelines as needed
- [ ] Set up monitoring
- [ ] Handle troubleshooting
- [ ] Optimize performance

## 📋 By Task

### Initial Setup

| Task | Document | Time |
|------|----------|------|
| Understand what's included | [PIPELINE-SETUP-SUMMARY.md](../PIPELINE-SETUP-SUMMARY.md) | 5 min |
| Complete setup from scratch | [COMPLETE-SETUP-GUIDE.md](./setup/COMPLETE-SETUP-GUIDE.md) | 2-3 hours |
| Create service connections | [create-service-connections.md](./setup/create-service-connections.md) | 30 min |
| Create variable groups | [VARIABLE-GROUPS.md](./setup/VARIABLE-GROUPS.md) | 30 min |
| Fix hardcoded backends | [fix-backend-configs.sh](./setup/fix-backend-configs.sh) | 15 min |

### Migration

| Task | Document | Time |
|------|----------|------|
| Plan migration | [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) | 1 hour |
| Execute migration | [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) | 2-3 days |
| Validate migration | [MIGRATION-GUIDE.md#validation--testing](./MIGRATION-GUIDE.md#validation--testing) | 1 day |

### Daily Operations

| Task | Document | Section |
|------|----------|---------|
| Deploy changes | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Deploying Changes |
| Check pipeline status | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Checking Pipeline Status |
| Approve production | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Approving Production |
| Download artifacts | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Downloading Artifacts |
| Troubleshoot issues | [README.md](./README.md) | Troubleshooting |

### Customization

| Task | Document | Section |
|------|----------|---------|
| Add new application | [single-app-pipeline.yml](./examples/single-app-pipeline.yml) | - |
| Destroy infrastructure | [destroy-pipeline.yml](./examples/destroy-pipeline.yml) | - |
| Modify template | [terraform-template.yml](./templates/terraform-template.yml) | - |
| Add new environment | [README.md](./README.md) | Pipeline Structure |

## 📖 Document Descriptions

### Core Documentation

#### [PIPELINE-SETUP-SUMMARY.md](../PIPELINE-SETUP-SUMMARY.md)
**Purpose**: Executive summary of pipeline setup  
**Audience**: All team members  
**Reading time**: 5 minutes  
**Content**:
- What was created and why
- Key features and benefits
- Quick start guide
- Configuration overview
- Success criteria

#### [README.md](./README.md)
**Purpose**: Comprehensive pipeline documentation  
**Audience**: Developers and DevOps engineers  
**Reading time**: 15-20 minutes  
**Content**:
- Pipeline architecture
- Deployment flows
- Security and best practices
- Common operations
- Troubleshooting guide
- Additional resources

#### [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
**Purpose**: Quick command reference  
**Audience**: All team members (keep handy!)  
**Reading time**: Quick lookup  
**Content**:
- Common operations
- Quick commands
- Troubleshooting tips
- Reference tables
- Pro tips

### Setup Guides

#### [setup/COMPLETE-SETUP-GUIDE.md](./setup/COMPLETE-SETUP-GUIDE.md)
**Purpose**: Step-by-step setup instructions  
**Audience**: Azure DevOps administrators  
**Time to complete**: 2-3 hours  
**Content**:
- Azure infrastructure setup
- Service connection creation
- Variable group configuration
- Environment setup
- Pipeline creation
- Testing and validation

#### [setup/create-service-connections.md](./setup/create-service-connections.md)
**Purpose**: Service connection setup guide  
**Audience**: Azure DevOps administrators  
**Time to complete**: 30 minutes  
**Content**:
- Service connection concepts
- Step-by-step creation
- Manual vs automatic setup
- Security best practices
- Troubleshooting

#### [setup/VARIABLE-GROUPS.md](./setup/VARIABLE-GROUPS.md)
**Purpose**: Variable group configuration  
**Audience**: Azure DevOps administrators  
**Time to complete**: 30 minutes  
**Content**:
- Variable group overview
- Required variables
- Azure Key Vault integration
- Security practices
- Troubleshooting

### Migration & Transition

#### [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md)
**Purpose**: Migrate from manual to pipeline deployments  
**Audience**: DevOps engineers and team leads  
**Time to complete**: 2-3 days  
**Content**:
- Migration phases
- Preparation steps
- Backend migration
- Pipeline deployment
- Cutover procedures
- Validation and testing

### Pipeline Files

#### [landing-zone-pipeline.yml](./landing-zone-pipeline.yml)
**Purpose**: Deploy common infrastructure  
**Type**: Production pipeline  
**Deploys**:
- VNet and networking
- Key Vault
- Storage accounts
- Log Analytics
- Application Insights
- Bastion (optional)

#### [applications-pipeline.yml](./applications-pipeline.yml)
**Purpose**: Deploy application workloads  
**Type**: Production pipeline  
**Deploys**:
- Windows Function Apps
- Linux Web Apps
- Application-specific resources

#### [templates/terraform-template.yml](./templates/terraform-template.yml)
**Purpose**: Reusable Terraform deployment steps  
**Type**: Template  
**Used by**: All pipelines  
**Features**:
- Terraform init/plan/apply
- Security scanning
- Artifact publishing
- Workspace management

### Examples

#### [examples/single-app-pipeline.yml](./examples/single-app-pipeline.yml)
**Purpose**: Template for single application deployment  
**Type**: Example  
**Use case**: Creating new application pipelines

#### [examples/destroy-pipeline.yml](./examples/destroy-pipeline.yml)
**Purpose**: Safe infrastructure teardown  
**Type**: Example (use with caution!)  
**Use case**: Decommissioning environments

### Scripts

#### [setup/create-variable-groups.sh](./setup/create-variable-groups.sh)
**Purpose**: Automate variable group creation  
**Language**: Bash  
**Prerequisites**: Azure DevOps CLI  
**Usage**: `./create-variable-groups.sh`

#### [setup/fix-backend-configs.sh](./setup/fix-backend-configs.sh)
**Purpose**: Remove hardcoded values from backend.tf  
**Language**: Bash  
**Prerequisites**: None  
**Usage**: `./fix-backend-configs.sh`

## 🗺️ Learning Path

### Beginner (New to Pipelines)

```
Week 1: Understanding
├─ Day 1-2: Read PIPELINE-SETUP-SUMMARY.md and README.md
├─ Day 3: Review example pipelines
├─ Day 4: Watch a pipeline run in Azure DevOps
└─ Day 5: Review QUICK-REFERENCE.md

Week 2: Practice
├─ Deploy to Dev environment
├─ Review plan outputs
├─ Practice approval workflow
└─ Troubleshoot a test issue
```

### Intermediate (Setting Up)

```
Week 1: Setup
├─ Follow COMPLETE-SETUP-GUIDE.md
├─ Create service connections
├─ Configure variable groups
├─ Set up environments
└─ Create pipelines

Week 2: Testing
├─ Deploy to Dev
├─ Deploy to QA
├─ Test approval flow
└─ Validate all components
```

### Advanced (Migrating)

```
Phase 1 (Week 1): Preparation
├─ Document current state
├─ Set up Azure DevOps
└─ Test in isolated environment

Phase 2 (Week 2): Migration
├─ Backup everything
├─ Update backend configs
├─ Migrate state files
└─ Test backend connectivity

Phase 3 (Week 3): Deployment
├─ Deploy Dev via pipeline
├─ Deploy QA via pipeline
├─ Deploy Prod via pipeline
└─ Validate all environments

Phase 4 (Week 4): Cutover
├─ Enable governance
├─ Train team
├─ Disable manual access
└─ Monitor and optimize
```

## 🔍 Finding Information

### By Topic

| Topic | Document | Section |
|-------|----------|---------|
| Architecture | [README.md](./README.md) | Architecture |
| Security | [README.md](./README.md) | Security & Best Practices |
| Deployment flow | [README.md](./README.md) | Deployment Flow |
| Troubleshooting | [README.md](./README.md) | Troubleshooting |
| Service connections | [create-service-connections.md](./setup/create-service-connections.md) | - |
| Variable groups | [VARIABLE-GROUPS.md](./setup/VARIABLE-GROUPS.md) | - |
| Migration | [MIGRATION-GUIDE.md](./MIGRATION-GUIDE.md) | - |
| Quick commands | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | - |

### By Problem

| Problem | Solution |
|---------|----------|
| Pipeline fails at init | [README.md#troubleshooting](./README.md#troubleshooting) |
| Service connection not found | [README.md#troubleshooting](./README.md#troubleshooting) |
| State lock error | [MIGRATION-GUIDE.md#troubleshooting](./MIGRATION-GUIDE.md#troubleshooting) |
| Permission denied | [QUICK-REFERENCE.md#troubleshooting](./QUICK-REFERENCE.md#troubleshooting) |
| Hardcoded subscription ID | [fix-backend-configs.sh](./setup/fix-backend-configs.sh) |
| Variable not found | [VARIABLE-GROUPS.md#troubleshooting](./setup/VARIABLE-GROUPS.md#troubleshooting) |

## 📊 Documentation Stats

| Document | Type | Length | Time to Read | Audience |
|----------|------|--------|--------------|----------|
| PIPELINE-SETUP-SUMMARY | Overview | ~2000 words | 5 min | All |
| README | Reference | ~4000 words | 15 min | Developers/DevOps |
| QUICK-REFERENCE | Cheatsheet | ~1500 words | Lookup | All |
| COMPLETE-SETUP-GUIDE | Tutorial | ~5000 words | 2-3 hours* | Admins |
| MIGRATION-GUIDE | Tutorial | ~4000 words | 2-3 days* | Engineers |
| VARIABLE-GROUPS | Reference | ~2000 words | 30 min* | Admins |
| create-service-connections | Tutorial | ~2000 words | 30 min* | Admins |

*Includes hands-on time

## 🎓 Training Materials

### Self-Service Learning

1. **Overview** (30 minutes)
   - Read: PIPELINE-SETUP-SUMMARY.md
   - Understand: What and why

2. **Setup** (3 hours)
   - Follow: COMPLETE-SETUP-GUIDE.md
   - Do: Complete setup

3. **Operations** (1 hour)
   - Read: QUICK-REFERENCE.md
   - Practice: Deploy to Dev

4. **Deep Dive** (2 hours)
   - Read: README.md
   - Study: Pipeline architecture

### Team Training Session

**Duration**: 2 hours

**Agenda**:
```
0:00-0:15  Overview & Architecture
0:15-0:30  Live Demo: Deployment Flow
0:30-0:45  Quick Reference Walkthrough
0:45-1:00  Hands-on: Deploy to Dev
1:00-1:15  Approval Workflow
1:15-1:30  Troubleshooting Common Issues
1:30-1:45  Best Practices
1:45-2:00  Q&A
```

**Materials**:
- PIPELINE-SETUP-SUMMARY.md (slides)
- QUICK-REFERENCE.md (handout)
- Live Azure DevOps demo

## 📞 Support Path

```
Issue Encountered
    ↓
Check QUICK-REFERENCE.md
    ↓
Not Found? → Check README.md Troubleshooting
    ↓
Still Stuck? → Check relevant setup guide
    ↓
Still Need Help? → Contact DevOps Team
```

## ✅ Checklist for New Team Members

### Day 1: Reading
- [ ] Read PIPELINE-SETUP-SUMMARY.md
- [ ] Read QUICK-REFERENCE.md
- [ ] Review pipeline runs in Azure DevOps

### Day 2: Learning
- [ ] Read README.md
- [ ] Understand deployment flow
- [ ] Review variable groups and service connections

### Day 3: Practice
- [ ] Create a test feature branch
- [ ] Make a small Terraform change
- [ ] Create PR and watch pipeline
- [ ] Review plan output

### Day 4: Approval
- [ ] Practice approval workflow (if approver)
- [ ] Understand what to check
- [ ] Know when to reject

### Day 5: Troubleshooting
- [ ] Review troubleshooting section
- [ ] Know who to contact for help
- [ ] Understand rollback procedures

## 🔗 Quick Links

- **Project Root**: `../`
- **Pipelines**: `./`
- **Templates**: `./templates/`
- **Setup**: `./setup/`
- **Examples**: `./examples/`
- **Backend Config**: `../backend-config/`
- **Modules**: `../modules/`
- **Projects**: `../project/`

## 📝 Document Version

**Pipeline Version**: 1.0.0  
**Last Updated**: October 2024  
**Maintained By**: DevOps Team  

---

**Need help navigating? Start with [PIPELINE-SETUP-SUMMARY.md](../PIPELINE-SETUP-SUMMARY.md)!** 🚀

