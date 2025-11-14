# cloud-org-infra

A simulated organizational Azure environment designed for hands-on learning, automation practice, and portfolio demonstration.  
This project demonstrates building scalable Azure infrastructure using PowerShell and GitHub Actions (CI/CD), authenticated via **OpenID Connect (OIDC)** — eliminating the need for stored secrets.

---

## 1. Introduction

This repository showcases a clean, modular, and enterprise-ready approach to deploying Azure environments using automation:

- Clear separation of responsibility and resource layout
- Consistent deployments through GitHub Actions pipelines
- Secure authentication using **OIDC** instead of saved credentials
- Reusable PowerShell modules for provisioning tasks
- Idempotent infrastructure provisioning (safe to re-run)

This setup can be extended into real-world enterprise blueprints.

---

## 2. Architecture Overview

The project simulates a common organizational Azure environment:

```
Tenant (Microsoft Entra ID)
│
└── Subscription (core-services / development)
    │
    ├── Resource Group: rg-core
    │   └── Storage Accounts (logs, data, state)
    │   └── Shared utilities (future: ACR, Key Vault)
    │
    ├── Resource Group: rg-network
    │   └── Virtual network + subnets
    │
    └── Resource Group: rg-security
        └── Azure Policy & RBAC model
```

This structure separates **core**, **network**, and **security** responsibilities — matching typical enterprise environments.

---

## 3. Technology Stack

| Component      | Purpose                                        |
|----------------|------------------------------------------------|
| **Azure**      | Cloud platform for infrastructure & workloads  |
| **PowerShell** | IaC and automation scripting engine            |
| **GitHub Actions** | CI/CD workflow orchestration           |
| **OIDC**       | Credentialless authentication from GitHub      |
| **RBAC & Policy** | Identity-based access and governance       |

---

## 4. CI/CD Deployment Workflow

GitHub Actions handles automated deployments:

1. Workflow is triggered (push / manual / schedule)
2. GitHub authenticates to Azure via **OIDC federation**
3. PowerShell installs Az modules
4. `deploy-environment.ps1` orchestrates resource provisioning
5. Validation & logging are performed at the end

This ensures **repeatable, stable, and secure deployments**.

---

## 5. Repository Structure

```
cloud-org-infra/
│
├── .github/workflows/
│   └── deploy.yml                  # CI/CD pipeline
│
├── automation/
│   ├── deploy-environment.ps1      # Full infra deployment orchestrator
│   ├── create-coreinfra.ps1        # Local deployment for core services
│   └── modules/
│       └── CoreInfrastructure/
│           ├── CoreInfrastructure.psm1
│           └── README.md
│
├── architecture/                   # Diagrams and conceptual documentation
├── documentation/                  # Guides, notes, walkthroughs
├── policy/                         # Azure Policy definitions (future)
└── security/                       # RBAC models & governance
```

This layout keeps code, modules, diagrams, automation logic, and governance separated and maintainable.

---

## 6. Core Infrastructure Module (New)

A reusable infrastructure provisioning module located at:

```
automation/modules/CoreInfrastructure/
```

### Functions Included
- **Ensure-ResourceGroup**
- **Ensure-StorageAccount**

These functions are **idempotent**, meaning they safely create or update resources without breaking existing setups.

### Local Deployment

```pwsh
cd .\automation\
Connect-AzAccount
.\create-coreinfra.ps1
```

### Creates:

- Resource Group (e.g., `rg-dev-weu`)
- ADLS Gen2 Storage Account (e.g., `stdevweu2401`)
- Standard tags:
  - `owner=lucian`
  - `env=dev`
  - `app=core`

---

## 7. ADLS Gen2 Storage Deployment (Core Infrastructure)

We provision a secure **ADLS Gen2** storage account with private networking and zero public exposure.

### Why ADLS Gen2?

- Directory and file-level ACLs  
- Required for advanced data workloads (Databricks, Synapse, ML pipelines)  
- RBAC-only access (no shared keys)  
- Supports enterprise-scale workflows  

### Quick Manual Deployment Example (PowerShell)

```powershell
$rg  = "rg-dev-weu"
$sa  = "stdweuweu2401"
$loc = "westeurope"
$tags = @{ owner="lucian"; env="dev"; app="core" }

New-AzResourceGroup -Name $rg -Location $loc -Tag $tags | Out-Null

New-AzStorageAccount `
  -Name $sa `
  -ResourceGroupName $rg `
  -Location $loc `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -EnableHierarchicalNamespace $true
```

---

## 8. Private Networking (Zero Public Exposure)

ADLS Gen2 is locked behind **Private Endpoints** inside a secured VNet.

### Components Added

| Component | Purpose |
|----------|---------|
| VNet + `subnet-data` | Private endpoint placement |
| Private Endpoints | Secure blob & dfs access |
| Private DNS Zones | Internal name resolution |
| RBAC | Identity-based access |

### Private Endpoint Creation (Blob + DFS)

```pwsh
$rgNet  = "rg-dev-weu"
$vnet   = "vnet-org-dev-weu"
$subData = "subnet-data"
$saObj = Get-AzStorageAccount -Name $sa -ResourceGroupName $rg

$plsBlob = New-AzPrivateLinkServiceConnection -Name "pls-$sa-blob" -PrivateLinkServiceId $saObj.Id -GroupId "blob"
$plsDfs  = New-AzPrivateLinkServiceConnection -Name "pls-$sa-dfs"  -PrivateLinkServiceId $saObj.Id -GroupId "dfs"

$v = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $rgNet
$sub = $v.Subnets | Where-Object Name -eq $subData

New-AzPrivateEndpoint -Name "pep-$sa-blob" -ResourceGroupName $rgNet -Location $loc -Subnet $sub -PrivateLinkServiceConnection $plsBlob
New-AzPrivateEndpoint -Name "pep-$sa-dfs"  -ResourceGroupName $rgNet -Location $loc -Subnet $sub -PrivateLinkServiceConnection $plsDfs
```

### Disable Public Access

```pwsh
Set-AzStorageAccount -ResourceGroupName $rg -Name $sa -PublicNetworkAccess Disabled
```

---

## 9. Verification

```pwsh
Get-AzPrivateEndpoint -ResourceGroupName $rgNet
(Get-AzStorageAccount -Name $sa -ResourceGroupName $rg).PublicNetworkAccess
```

Expected output:

- Private Endpoints: `Succeeded`
- Public Access: `Disabled`
- DNS Zones contain private IPs

✔ Traffic internal-only  
✔ No shared keys  
✔ Zero public exposure  
✔ Enterprise-grade storage

---

## 10. How to Deploy (CI/CD)

From GitHub UI:

**Actions → Deploy Azure infra → Run workflow**

No secrets stored. Everything uses **OIDC** + RBAC identity.

---

## 11. Planned Enhancements

- Add VNet subnets + NSGs
- Add Key Vault + Container Registry
- Add monitoring (Log Analytics + Alerts)
- Add Azure Policy for naming, tagging, compliance  
- Expand automation modules for app services, networks, and databases

---

**Status:** Active learning & development project (Azure + IaC + Automation).

