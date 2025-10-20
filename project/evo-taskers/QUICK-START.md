# Quick Start: Deploy Shared Services Architecture

## TL;DR - Commands to Run

```bash
# 1. Deploy Common (if not already deployed)
cd project/evo-taskers/common
terraform init
terraform apply -var-file="dev.tfvars"

# 2. Deploy Shared Services (NEW)
cd ../shared
terraform init
terraform apply -var-file="dev.tfvars"

# 3. Deploy UnlockBookings
cd ../unlockbookings
terraform init
terraform apply -var-file="dev.tfvars"

# 4. Deploy AutomatedDataFeed
cd ../automateddatafeed
terraform init
terraform apply -var-file="dev.tfvars"

# 5. Validate
cd ../
./validate-deployment.sh dev
```

## Prerequisites Checklist

- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform >= 1.9.0 installed
- [ ] Access to Azure subscription
- [ ] Backend storage account exists (`stevotaskersstatepoc`)
- [ ] Have subscription ID ready

## Before You Start

### 1. Update `shared/dev.tfvars`

```bash
cd project/evo-taskers/shared
nano dev.tfvars  # or use your preferred editor
```

Update this line:
```hcl
subscription_id = "your-actual-subscription-id"  # ← CHANGE THIS
```

Get your subscription ID:
```bash
az account show --query id -o tsv
```

### 2. Verify Common Is Deployed

```bash
cd ../common
terraform output

# Should show outputs like:
# resource_group_name = "rg-evotaskers-dev-eus"
# vnet_id = "/subscriptions/..."
# etc.
```

If common is not deployed, deploy it first:
```bash
terraform init
terraform apply -var-file="dev.tfvars"
```

## Step-by-Step Deployment

### Step 1: Deploy Shared Services (5 minutes)

```bash
cd project/evo-taskers/shared

# Initialize
terraform init

# Review what will be created
terraform plan -var-file="dev.tfvars"

# Expected: 2 App Service Plans
# - Windows Function Plan (EP1)
# - Logic App Plan (WS1)

# Apply changes
terraform apply -var-file="dev.tfvars"

# Verify
terraform output
```

**Expected Outputs:**
```
windows_function_plan_id = "/subscriptions/.../asp-evotaskers-dev-eus-functions-windows"
logic_app_plan_id = "/subscriptions/.../asp-evotaskers-dev-eus-logicapps"
```

### Step 2: Deploy UnlockBookings (3 minutes)

```bash
cd ../unlockbookings

# Initialize
terraform init

# Review changes
terraform plan -var-file="dev.tfvars"

# Expected: Logic App will use shared plan

# Apply
terraform apply -var-file="dev.tfvars"

# Verify
terraform output
```

### Step 3: Deploy AutomatedDataFeed (3 minutes)

```bash
cd ../automateddatafeed

# Initialize
terraform init

# Review changes
terraform plan -var-file="dev.tfvars"

# Expected: Function App will use shared plan

# Apply
terraform apply -var-file="dev.tfvars"

# Verify
terraform output
```

### Step 4: Validate Deployment (1 minute)

```bash
cd ../
./validate-deployment.sh dev
```

**Expected Output:**
```
==========================================
EVO-TASKERS Deployment Validation
Environment: dev
==========================================

1. Fetching Common Infrastructure State...
✓ Common state file exists

2. Checking Resource Group...
✓ Resource Group 'rg-evotaskers-dev-eus' exists

...

7. Checking App Service Plans...
✓ Found 2 App Service Plan(s)
✓ Windows Function Plan: 1 app(s)
✓ Logic App Plan: 1 app(s)

...

✓ Validation Complete!
```

## Verification Checklist

After deployment, verify:

### In Azure Portal

1. **Navigate to Resource Group**
   - Go to: `rg-evotaskers-dev-eus`

2. **Check App Service Plans**
   - [ ] `asp-evotaskers-dev-eus-functions-windows` exists
   - [ ] Shows "Apps: 1" (or more if you deployed others)
   - [ ] `asp-evotaskers-dev-eus-logicapps` exists
   - [ ] Shows "Apps: 1"

3. **Check Applications**
   - [ ] `la-evotaskers-dev-eus-unlockbookings-workflow` exists (Logic App)
   - [ ] `fa-evotaskers-dev-eus-automateddatafeed` exists (Function App)

4. **Verify Plan Usage**
   - Click on Function App → Settings → Configuration → General Settings
   - [ ] "App Service Plan" shows shared plan name

### Via Azure CLI

```bash
# Check App Service Plans
az appservice plan list --resource-group rg-evotaskers-dev-eus --output table

# Check which apps are on which plans
az functionapp list --resource-group rg-evotaskers-dev-eus \
  --query "[].{Name:name, Plan:appServicePlanId}" -o table

az logicapp list --resource-group rg-evotaskers-dev-eus \
  --query "[].{Name:name, Plan:appServicePlanId}" -o table
```

## Troubleshooting

### Error: "Backend configuration not found"

**Solution:**
```bash
terraform init
```

### Error: "State file not found"

**Cause:** Previous layer not deployed

**Solution:** Deploy in order: common → shared → apps

### Error: "Resource already exists"

**Cause:** Resource was created outside of Terraform

**Solution:** Import or remove the resource:
```bash
# Import
terraform import <resource_type>.<name> <azure_resource_id>

# Or remove from Azure
az <resource-type> delete --name <name> --resource-group <rg>
```

### Apps not using shared plan

**Cause:** Remote state configuration issue

**Solution:** Verify data source in app's `main.tf`:
```hcl
data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    key = "shared/evo-taskers-shared-${var.environment}.tfstate"
    # ... other config
  }
}
```

## Cost Check

After deployment, check costs:

```bash
# View plan details
az appservice plan show \
  --name asp-evotaskers-dev-eus-functions-windows \
  --resource-group rg-evotaskers-dev-eus \
  --query "{Name:name, SKU:sku.name, Apps:numberOfSites, Tier:sku.tier}"

# Expected: EP1, 1+ apps
```

**Expected Monthly Cost:**
- Windows Function Plan (EP1): ~$150
- Logic App Plan (WS1): ~$225
- **Total: ~$375/month**

Compare to before (if apps had individual plans): ~$825/month
**Savings: ~$450/month**

## Next Steps

After successful deployment:

1. **Deploy remaining apps:**
   - [ ] dashboard
   - [ ] sendgrid
   - [ ] autoopenshorex

2. **Deploy to QA:**
   ```bash
   # Update tfvars for QA
   # Deploy: common → shared → apps
   ```

3. **Deploy to Production:**
   ```bash
   # Update prod.tfvars
   # Enable autoscaling for prod shared plan
   # Deploy: common → shared → apps
   ```

4. **Set up monitoring:**
   - [ ] Configure Azure Monitor alerts
   - [ ] Set up cost alerts
   - [ ] Enable Application Insights

## Rollback

If you need to rollback:

```bash
# Rollback apps
cd project/evo-taskers/automateddatafeed
terraform destroy -var-file="dev.tfvars"

cd ../unlockbookings
terraform destroy -var-file="dev.tfvars"

# Rollback shared
cd ../shared
terraform destroy -var-file="dev.tfvars"

# Common stays (don't destroy unless necessary)
```

## Support

- 📖 [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) - Full deployment guide
- 📋 [SHARED-MIGRATION-SUMMARY.md](./SHARED-MIGRATION-SUMMARY.md) - Migration summary
- 📊 [FILE-CHANGES-SUMMARY.md](./FILE-CHANGES-SUMMARY.md) - All file changes
- 🔧 [validate-deployment.sh](./validate-deployment.sh) - Validation script

---

**Time to Deploy:** ~15 minutes  
**Difficulty:** Easy  
**Cost Impact:** -55% (saves ~$450/month)  
**Rollback Available:** Yes

