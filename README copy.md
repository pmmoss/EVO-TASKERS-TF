# Azure Landing Zone Terraform Template

This repository provides a production-grade, modular, and secure Terraform template for deploying Azure Landing Zones and application workloads. It follows Microsoft best practices for naming, security, and maintainability with secure-by-default configurations.

## 🏗️ Architecture Overview

This landing zone creates a comprehensive Azure infrastructure with the following components:

### Core Infrastructure
- **Resource Group**: Centralized resource management
- **Virtual Network**: Hub-spoke architecture with multiple subnets
- **Network Security Groups**: Secure traffic flow controls
- **Route Tables**: Default routing to hub firewall

### Security & Monitoring
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring
- **Key Vault**: Secure secrets management with private endpoints
- **Storage Account**: Secure data storage with private endpoints
- **Bastion Host**: Secure administrative access

### Application Platform
- **App Service Plan**: Scalable application hosting
- **App Service**: Web application hosting with VNET integration
- **Private Endpoints**: Secure connectivity for all services

## 🔒 Security Features

### Secure by Default
- **Private Endpoints**: All services use private connectivity
- **VNET Integration**: App Service integrated with private network
- **Public Access Disabled**: No public access to sensitive services
- **RBAC**: Role-based access control for all resources
- **Network Security Groups**: Restrictive traffic rules
- **Diagnostic Logging**: Comprehensive audit trails

### Network Architecture
```
VNET (10.0.0.0/16)
├── App Service Integration Subnet (10.0.1.0/24)
├── Private Endpoints Subnet (10.0.2.0/24)
├── Gateway Subnet (10.0.3.0/24)
└── Bastion Subnet (10.0.4.0/24)
```

## 📁 Project Structure

```
├── global/                    # Core landing zone configuration
│   ├── main.tf               # Main infrastructure definition
│   ├── variables.tf          # Global variables
│   ├── outputs.tf            # Global outputs
│   └── locals.tf             # Common local values
├── modules/                   # Reusable infrastructure modules
│   ├── network/              # VNET, subnets, NSGs, routing
│   ├── keyvault/             # Key Vault with private endpoints
│   ├── storage/              # Storage account with private endpoints
│   ├── log_analytics/        # Log Analytics workspace
│   ├── appinsights/          # Application Insights
│   ├── app_service/          # App Service Plan and App Service
│   ├── bastion/              # Bastion host for secure access
│   └── naming/               # Microsoft-compliant naming convention
└── environments/             # Environment-specific configurations
    └── revms-wus2/
        └── dev/              # Development environment
            ├── main.tf       # Environment configuration
            └── terraform.tfvars # Environment variables
```

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- Terraform >= 1.5.0
- Appropriate Azure permissions

### 1. Configure Environment
```bash
cd environments/revms-wus2/dev
```

### 2. Update Variables
Edit `terraform.tfvars` with your specific values:
```hcl
# Basic Configuration
project     = "your-project"
environment = "dev"
location    = "West US 2"

# Security Configuration
admin_object_ids = [
  "your-admin-object-id"
]

# Network Configuration
vnet_address_space = ["10.1.0.0/16"]
hub_firewall_ip    = "your-hub-firewall-ip"
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

## 🔧 Configuration Options

### Network Configuration
- **VNET Address Space**: Customizable CIDR blocks
- **Subnet Configuration**: Pre-configured subnets for different purposes
- **Hub Integration**: Default routing to hub firewall
- **NSG Rules**: Secure traffic flow controls

### Security Configuration
- **RBAC**: Role-based access control for all resources
- **Private Endpoints**: Secure connectivity for all services
- **Network Rules**: Restrictive network access policies
- **Diagnostic Logging**: Comprehensive audit trails

### App Service Configuration
- **OS Type**: Linux or Windows
- **SKU**: Configurable pricing tiers
- **VNET Integration**: Private network connectivity
- **Application Settings**: Custom environment variables

## 📊 Monitoring & Logging

### Diagnostic Settings
All resources are configured with comprehensive diagnostic logging:
- **Key Vault**: Audit events and policy evaluations
- **Storage**: Read, write, and delete operations
- **App Service**: HTTP logs, console logs, and application logs
- **Application Insights**: Traces, dependencies, requests, and exceptions
- **Log Analytics**: Audit and security logs

### Log Retention
- **Standard Retention**: 365 days for all logs
- **Cost Optimization**: Configurable retention policies
- **Compliance**: Audit-ready logging for regulatory requirements

## 🔄 CI/CD Integration

### Azure DevOps Pipeline Access
The infrastructure is designed to work with Azure DevOps hosted agents:
- **Default Routing**: Traffic routes through hub firewall
- **Private Connectivity**: All services accessible via private endpoints
- **RBAC Integration**: Pipeline service principals can be granted appropriate roles

### Deployment Strategy
1. **Infrastructure First**: Deploy landing zone infrastructure
2. **Application Deployment**: Deploy applications to App Service
3. **Monitoring Setup**: Configure application monitoring
4. **Security Hardening**: Apply additional security policies

## 🛠️ Customization

### Adding New Modules
1. Create module in `/modules/your-module/`
2. Follow existing module structure
3. Add to global `main.tf`
4. Configure in environment files

### Environment-Specific Configuration
- **Development**: Basic SKUs, minimal monitoring
- **Production**: High availability, comprehensive monitoring
- **Staging**: Production-like with reduced scale

## 📚 References

- [Microsoft Azure Resource Naming](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- [CAF Terraform Modules](https://github.com/Azure/terraform-azurerm-caf)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Azure Landing Zone Architecture](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
