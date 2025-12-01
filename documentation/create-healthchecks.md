# Health Checks Module — create-healthchecks.ps1

## Overview
This module performs a full environment health check across all core Azure resources deployed in the Landing Zone.  
It validates presence, consistency, configuration integrity, and security posture for each resource.

The script outputs:
- A human-friendly health report  
- A structured JSON object for pipelines  
- A pass/fail summary for automation workflows  

This is designed for:
- CI/CD pipelines  
- Daily operational validation  
- Pre-deployment checks  
- Audits and compliance reviews  

---

## What the module validates

### 1. Resource Group validation
Ensures the expected Resource Group exists:
- `rg-<App>-<Environment>-<Region>`

Checks:
- Existence  
- Location correctness  
- Tag compliance (app, environment, region, owner)

---

### 2. Virtual Network (VNet)
Ensures the expected VNet exists:
- `vnet-<App>-<Environment>-<Region>`

Validates:
- Address space  
- Required subnets:
  - subnet-core
  - subnet-data
  - subnet-app  
- Subnet address prefixes  
- Delegations (if applicable)

---

### 3. Network Security Groups (NSGs)
Validates all NSGs:
- Existence  
- Required inbound/outbound rules  
- Naming convention  
- Association with subnets  

---

### 4. Storage Account
Checks the storage account:
- Existence  
- Naming convention  
- TLS version  
- Public network access  
- Minimum security baseline  
- Tags  
- SKU (Standard_LRS expected)

---

### 5. Key Vault
Validates Key Vault:
- Existence  
- Soft delete  
- RBAC vs Access Policies  
- Public network access  
- Firewall configuration  
- Tag compliance  
- Diagnostic settings (if configured)

---

### 6. Log Analytics Workspace (LAW)
Validates LAW:
- Existence  
- Naming correctness  
- Tags  
- Retention policy  
- Whether diagnostic settings are sending logs to it  

---

### 7. App Service + App Service Plan
Checks:
- Existence  
- SKU (Starter/Basic/Standard)  
- HTTPS-only enabled  
- System-assigned identity enabled  
- VNet integration (optional)  
- Diagnostic settings (if configured)

---

## Output

The script returns the following structured output:

### ✔ Human-friendly report
Example:
[OK] Resource Group exists
[OK] VNet is correctly configured
[WARN] Storage Account does not enforce TLS 1.2
[ERROR] App Service missing identity


### ✔ JSON summary for pipelines
Example:
```json
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
✔ CI/CD return values

0 → Healthy

1 → Warnings

2 → Errors

Usage
PowerShell (local)
.\create-healthchecks.ps1 `
    -Environment dev `
    -App core `
    -Region weu `
    -Location westeurope
& $healthchecksScript -Environment $Environment `
                      -App         $App `
                      -Region      $Region `
                      -Location    $Location
- name: Run environment health check
  run: pwsh ./automation/create-healthchecks.ps1 -Environment dev -App core -Region weu -Location westeurope



Why clients care

This module gives organizations:
- Immediate visibility into infrastructure health
- Security baseline validation
- Cost control by catching misconfigurations early
- Compliance-friendly evidence (ISO, SOC2, CIS)
- A predictable way to validate every environment

Why it matters for you (consultant)

You deliver:
- A repeatable audit tool
- A real, tangible asset in your Landing Zone offering
- Automated governance
- Professional, enterprise-level validation for client environments
