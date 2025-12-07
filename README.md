# cloud-org-infra

## Introduction

cloud-org-infra is an enterprise-grade Azure Infrastructure Automation Framework built entirely with PowerShell.
It provides a fully modular, idempotent, and production-ready approach for provisioning complete application environments across multiple regions and stages.

This repository is engineered for:

- Cloud Automation Engineers
- DevOps Practitioners
- Azure Infrastructure Architects
- Engineers preparing a professional cloud automation portfolio

The goal is to deliver a repeatable baseline infrastructure that organizations can adopt or extend.

---

## Key Capabilities

- Modular Infrastructure as Code (IaC) using PowerShell
- Idempotent execution - safe to run multiple times
- Strict naming and tagging standards for enterprise-scale environments
- Security built-in (Key Vault, RBAC, hardened App Service config)
- Production observability, including:
  - Log Analytics Workspace
  - Application Insights
  - Baseline alerting (CPU, 5xx errors)
- Unified orchestration with a single deployment command
- CI/CD ready for GitHub Actions and Azure DevOps

---

## High-Level Architecture

Each environment consists of:

- Resource Group
- Virtual Network (VNet) and Subnets
- Network Security Groups
- Storage Account
- Azure Key Vault
- App Service Plan and App Service
- Log Analytics Workspace
- Application Insights
- Extended App Service Configuration:
  - HTTPS enforcement
  - TLS minimum version
  - Managed Identity
  - Diagnostic logs sent to Log Analytics
- Alerts:
  - CPU High
  - HTTP 5xx spike
- RBAC (Reader, Contributor, Key Vault Secrets User)

---

## Standardized Naming Convention

Examples:

- rg-core-dev-weu
- vnet-core-dev-weu
- kv-core-dev-weu
- stcoredevweuNNN
- asp-core-dev-weu
- app-core-dev-weu
- law-core-dev-weu
- appi-core-dev-weu
- ag-core-dev-weu

This ensures consistency, discoverability, and compliance across environments.

---

## Orchestration Flow

The orchestration is performed by:

automation/deploy-environment.ps1

Execution sequence:

1. create-rg.ps1
2. create-network.ps1
3. create-nsgs.ps1
4. create-storage.ps1
5. create-keyvault.ps1
6. create-loganalytics.ps1
7. create-appservice.ps1
8. create-appinsights.ps1
9. create-appservice-extended.ps1
10. create-alerts.ps1
11. create-rbac.ps1

Each module is fully independent and documented under /documentation.

---

## Requirements

- Azure Subscription
- PowerShell 7 or later
- Az PowerShell modules installed
- Authentication via:
  - Connect-AzAccount
  OR
  - Service Principal environment variables:

AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

---

## Deployment Example

Example: Deploy the core application into dev environment in West Europe:

cd automation
.\deploy-environment.ps1 -Environment dev -App core -Region weu -Location westeurope

This will deploy:

- Networking
- Security
- Compute
- Observability
- RBAC

in a fully automated sequence.

---

## Configuring Alerts

To enable or adjust alert recipients, edit the Alerts step in the orchestrator:

-AlertEmails @("ops@example.com", "oncall@example.com")

---

## Configuring RBAC

To assign role-based access control, supply Azure AD Object IDs:

-ReaderObjectIds @("aad-object-id-1")
-ContributorObjectIds @("aad-object-id-2")
-KeyVaultSecretsUserObjectIds @("aad-object-id-3")

Assignments are idempotent and safe to run repeatedly.

---

## Module Overview

Core IaC modules:

- create-rg.ps1
- create-network.ps1
- create-nsgs.ps1
- create-storage.ps1
- create-keyvault.ps1
- create-appservice.ps1
- create-loganalytics.ps1
- create-appinsights.ps1
- create-appservice-extended.ps1
- create-alerts.ps1
- create-rbac.ps1

Documentation lives under /documentation.

---

## Operational Model

### Reprovisioning

The system is idempotent:

- Running the same deploy command multiple times will not break the environment
- Existing resources are reused
- Missing components are provisioned automatically

### Extending Infrastructure

New modules follow the same pattern:

- strict naming
- parameter consistency
- idempotent logic
- integrated with deploy-environment.ps1

### Deleting Environments

Optional cleanup script:

automation/cleanup.ps1

Deletes the environment resource group and all dependent resources.

---

## Troubleshooting Guide

### Authentication Errors

Ensure the correct environment variables are set or run Connect-AzAccount interactively.

### Resource Already Exists

All modules are idempotent. This is expected. Deployment will continue safely.

### Missing Role Definitions

Some tenants may not include:

- Key Vault Secrets User

If missing, the RBAC module will emit a warning and continue.

### Alerts Not Triggering

Verify:

- The Action Group exists
- Correct email addresses
- Application Insights is receiving data

---

## CI/CD Integration

This project is ready for CI/CD pipelines.

Typical pipeline:

1. Checkout repository
2. Install PowerShell 7
3. Install Az modules
4. Authenticate to Azure
5. Run deploy-environment.ps1

Multi-environment pipelines (dev to test to prod) can reuse the same script.

---

## Roadmap

Upcoming enhancements:

- Terraform mirror
- Optional Linux App Service hosting
- Optional Application Gateway and WAF module
- Optional SQL and PostgreSQL automation modules
- Optional end-to-end GitHub Actions pipeline templates

---

## License

Internal use and portfolio demonstration only.
Not for commercial redistribution without permission.

---

## Author

Engineered as a senior-level cloud automation portfolio project.
Designed for extensibility, clarity, and long-term maintainability.

---

# Diagnostics Automation - Azure Infrastructure

This project automatically configures Azure Monitor Diagnostic Settings for core infrastructure resources using PowerShell and Azure REST API.

The script create-diagnostics.ps1 links:

- Storage Accounts
- Key Vaults

to a Log Analytics Workspace, ensuring that all logs and metrics are collected centrally.

---

## What this script does

1. Loads and installs required Az PowerShell modules:
   - Az.Accounts
   - Az.OperationalInsights
   - Az.Resources
   - Az.KeyVault
   - Az.Storage

2. Resolves infrastructure naming automatically:
   - Resource Group: rg-{app}-{environment}-{region}
   - Log Analytics Workspace: law-{app}-{environment}-{region}
   - Key Vault: kv-{app}-{environment}-{region}

3. Validates that:
   - The Resource Group exists
   - The Log Analytics Workspace exists

4. Uses Azure REST API via Invoke-AzRestMethod to configure diagnostics:
   - Sends all logs using categoryGroup allLogs
   - Sends all metrics using category AllMetrics
   - Connects them to the Log Analytics Workspace

5. Applies diagnostics to:
   - Key Vault if found
   - Storage Account discovered automatically by tags app and environment

If a resource is missing, the script safely skips it and continues deployment.

---

## Why REST API instead of Set-AzDiagnosticSetting

The native PowerShell cmdlet Set-AzDiagnosticSetting is unreliable across environments and Az module versions.

Using the REST API guarantees:

- Full Azure API compatibility
- Correct api-version handling
- No dependency on unstable PowerShell cmdlets
- Same authentication context as the GitHub Actions runner

---

## Parameters

The script requires the following parameters:

- Environment (dev, test, prod)
- App (application name)
- Region (short Azure region, for example weu)
- Location (full Azure region, for example westeurope)

---

## Output

At the end of execution, the script returns:

- Log Analytics Workspace object
- Key Vault name
- Resource Group name

---

## Result

After successful deployment:

- Storage logs and metrics are sent to Log Analytics
- Key Vault logs and metrics are sent to Log Analytics if the Key Vault exists
- All diagnostics configuration is applied automatically during infrastructure deployment