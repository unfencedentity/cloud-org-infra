# Health Checks Module — create-healthchecks.ps1

## Overview
This module performs a full environment health check across all core Azure resources deployed in the Landing Zone.  
It validates presence, consistency, configuration integrity, and security posture for every component.

The script outputs:
- A human-friendly health report
- A structured JSON object for CI/CD pipelines
- A pass/warn/fail summary for automation workflows

Designed for:
- CI/CD pipelines
- Daily operational validation
- Pre-deployment checks
- Audits and compliance reviews

---

## What the module validates

### 1. Resource Group
Validates:
- Existence (`rg-<App>-<Environment>-<Region>`)
- Location
- Required tags: app, environment, region, owner

---

### 2. Virtual Network (VNet)
Validates:
- Existence (`vnet-<App>-<Environment>-<Region>`)
- Address space correctness
- Mandatory subnets:
  - subnet-core
  - subnet-data
  - subnet-app
- Subnet address prefixes
- Delegations (if used)

---

### 3. Network Security Groups (NSGs)
Validates:
- Existence
- Naming convention
- Required NSG rules
- Association with subnets

---

### 4. Storage Account
Validates:
- Existence
- Naming convention
- TLS 1.2 enforced
- Public network access disabled (recommended)
- SKU = Standard_LRS
- Tags
- Security baseline checks

---

### 5. Key Vault
Validates:
- Existence
- Soft delete enabled
- RBAC vs Access Policies mode
- Public network access
- Firewall configuration
- Tags
- Diagnostic settings (if used)

---

### 6. Log Analytics Workspace (LAW)
Validates:
- Existence
- Naming correctness
- Tags
- Retention policy
- Resources correctly sending logs to LAW

---

### 7. App Service & App Service Plan
Validates:
- Existence
- Correct SKU
- HTTPS-only enabled
- Managed Identity enabled
- Diagnostic settings applied
- VNet integration (optional)

---

## Output

### Human-friendly console report
Example:
[OK] Resource Group exists  
[OK] VNet is correctly configured  
[WARN] Storage Account does not enforce TLS 1.2  
[ERROR] App Service missing identity  

### JSON summary for CI/CD
Example:
{
  "Environment": "dev",
  "App": "core",
  "Region": "weu",
  "Status": "Warning",
  "Issues": [
    "Storage TLS version < 1.2",
    "App Service missing identity"
  ]
}

### CI/CD return codes
0 → Healthy  
1 → Warnings  
2 → Errors  

---

## Usage

### PowerShell (local)
.\create-healthchecks.ps1 -Environment dev -App core -Region weu -Location westeurope

### Using inside deploy-environment.ps1
& $healthchecksScript -Environment $Environment -App $App -Region $Region -Location $Location

### GitHub Actions
- name: Run environment health check  
  run: pwsh ./automation/create-healthchecks.ps1 -Environment dev -App core -Region weu -Location westeurope

---

## Why clients care
This module provides:
- Immediate visibility into environment health
- Security baseline enforcement
- Early detection of misconfigurations
- Compliance-friendly evidence for ISO / SOC2 / CIS
- A predictable validation layer for all environments

---

## Why it matters for you (consultant)
You deliver:
- A repeatable audit tool
- A valuable asset in your Landing Zone offering
- Automated governance and validation
- Enterprise-grade checks clients are willing to pay for
