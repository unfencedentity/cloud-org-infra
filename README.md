# cloud-org-infra

A simulated organizational Azure environment designed for hands-on learning, automation practice, and portfolio demonstration.  
This project demonstrates building scalable Azure infrastructure using PowerShell and GitHub Actions (CI/CD), authenticated via OpenID Connect (OIDC) — eliminating the need for stored secrets.

---

## 1. Introduction

This repository showcases a clean, modular approach to deploying Azure environments using automation:

- Clear separation of responsibility and resource layout
- Consistent deployments through GitHub Actions pipelines
- Secure authentication using **OpenID Connect (OIDC)** instead of saved credentials
- Reusable PowerShell modules for provisioning tasks

This setup can be extended into real-world enterprise blueprints.

---

## 2. Architecture Overview

This project simulates a common organizational Azure structure:

```text
Tenant (Microsoft Entra ID)
│
└── Subscription (core-services / development / sandbox)
    │
    ├── Resource Group: rg-core
    │   └── Storage Accounts (logs, data, state)
    │   └── Shared Utilities (future: Key Vault, Container Registry, etc.)
    │
    ├── Resource Group: rg-network
    │   └── Virtual Network + Subnets (future expansion)
    │
    └── Resource Group: rg-security
        └── RBAC role assignments
        └── Azure Policy (naming, compliance & governance)
```

This keeps **core**, **network**, and **security** responsibilities clearly separated — similar to real enterprise environments.

---

## 3. Technology Stack

| Component      | Purpose                                        |
|----------------|------------------------------------------------|
| Azure          | Cloud platform where resources are deployed    |
| PowerShell     | IaC scripting engine for automation modules    |
| GitHub Actions | CI/CD workflow engine                          |
| OIDC           | Secure authentication — no stored secrets      |
| RBAC & Policy  | Org-wide governance and access control         |

---

## 4. Deployment Workflow (CI/CD)

The deployment pipeline runs through GitHub Actions:

1. Workflow is triggered (manual / push / schedule)
2. GitHub authenticates to Azure using **OIDC**
3. PowerShell modules install required Az tools
4. `deploy-environment.ps1` creates/updates resources
5. Output is logged and validated

This ensures **repeatable, consistent deployments**.

---

## 5. Folder Structure

```text
cloud-org-infra/
│
├── .github/workflows/          # CI/CD pipelines (GitHub Actions)
│   └── deploy.yml              # Deployment workflow
│
├── automation/                 # PowerShell automation logic
│   ├── deploy-environment.ps1  # Main environment deployment script
│   └── modules/                # Reusable helper functions
│
├── architecture/               # Diagrams and conceptual layouts (future)
├── policy/                     # Azure Policy definitions
├── security/                   # RBAC mappings & governance
└── documentation/              # Notes & usage guides
```

This layout keeps code, docs, and governance **separated and maintainable**.

---

## 6. How to Deploy

From GitHub UI →  
**Actions → Deploy Azure infra → Run Workflow**

No local secrets required.  
Authentication happens via **OIDC Federation**.

---

## 7. Planned Enhancements

- Add VNet subnets + NSGs
- Add Key Vault + Container Registry
- Expand tagging & naming governance
- Add monitoring setup (Log Analytics + Alerts)

---

**Status:** Active learning & development project.

## Storage Provisioning (ADLS Gen2)

We provision a secure storage account with hierarchical namespace enabled (ADLS Gen2) for data workflows, automation pipelines, and log retention.

### Why ADLS Gen2?
- Supports directory & file-level ACLs for fine-grained access
- Required for advanced data workloads (Databricks, Synapse, ML jobs)
- Enables enterprise logging & automation artifact storage
- No access keys required — **RBAC-based security only**

### Quick Provision (PowerShell)
```powershell
# Variables
$rg  = "rg-dev-weu"
$sa  = "stdweuweu2401"
$loc = "westeurope"
$tags = @{ owner="lucian"; env="dev"; app="core" }

# Create or update Resource Group
New-AzResourceGroup -Name $rg -Location $loc -Tag $tags | Out-Null

# Create ADLS Gen2 Storage Account
New-AzStorageAccount `
  -Name $sa `
  -ResourceGroupName $rg `
  -Location $loc `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -EnableHierarchicalNamespace $true

# Assign RBAC to signed-in user (no access keys)
$userId = (Get-AzADUser -SignedIn).Id
New-AzRoleAssignment `
  -ObjectId $userId `
  -RoleDefinitionName "Storage Blob Data Contributor" `
  -Scope "/subscriptions/$(Get-AzContext).Subscription.Id/resourceGroups/$rg/providers/Microsoft.Storage/storageAccounts/$sa"

## Secure Storage Access with Private Endpoints (Zero Public Exposure)

We ensure that the ADLS Gen2 storage account is accessible **only internally**, through **Private Endpoints** bound to a controlled virtual network.  
This prevents public exposure and guarantees that all traffic stays **on the Azure backbone**.

### Why This Matters
| Component | Purpose |
|---------|---------|
| ADLS Gen2 | Data lake storage for automation / workload data |
| VNet | Network boundary for organization traffic |
| Subnet `subnet-data` | Placement for private endpoints |
| Private Endpoints | Secure access to BLOB and DFS endpoints |
| Private DNS Zones | Internal DNS resolution for blob & dfs |
| RBAC | Identity-based access (no shared keys needed) |

**Result:**  
✔ No public internet access  
✔ No shared keys  
✔ Identity & role-based access  
✔ Private traffic inside Azure network only  

---

## Step 1 — Variables
```pwsh
$rg     = "rg-dev-weu"
$loc    = "westeurope"
$sa     = "stdeweu2401"
$rgNet  = "rg-dev-weu"
$vnet   = "vnet-org-dev-weu"
$subData = "subnet-data"
```

---

## Step 2 — Get Storage Account Object
```pwsh
$saObj = Get-AzStorageAccount -Name $sa -ResourceGroupName $rg | Select-Object -First 1
```

---

## Step 3 — Create Private Link Service Connections (Blob + DFS)
```pwsh
# Blob service private link
$plsBlob = New-AzPrivateLinkServiceConnection `
  -Name "pls-$sa-blob" `
  -PrivateLinkServiceId $saObj.Id `
  -GroupId "blob"

# DFS (Data Lake) private link
$plsDfs = New-AzPrivateLinkServiceConnection `
  -Name "pls-$sa-dfs" `
  -PrivateLinkServiceId $saObj.Id `
  -GroupId "dfs"
```

---

## Step 4 — Create Private Endpoints in the Data Subnet
```pwsh
# Extract subnet object from VNet
$v = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $rgNet
$sub = $v.Subnets | Where-Object Name -eq $subData

# Blob endpoint
New-AzPrivateEndpoint `
  -Name "pep-$sa-blob" `
  -ResourceGroupName $rgNet `
  -Location $loc `
  -Subnet $sub `
  -PrivateLinkServiceConnection $plsBlob `
  -ErrorAction SilentlyContinue | Out-Null

# DFS endpoint
New-AzPrivateEndpoint `
  -Name "pep-$sa-dfs" `
  -ResourceGroupName $rgNet `
  -Location $loc `
  -Subnet $sub `
  -PrivateLinkServiceConnection $plsDfs `
  -ErrorAction SilentlyContinue | Out-Null
```

---

## Step 5 — Create Private DNS Zones for blob + dfs
```pwsh
$zoneBlob = "privatelink.blob.core.windows.net"
$zoneDfs  = "privatelink.dfs.core.windows.net"

$zBlobId = (New-AzPrivateDnsZoneGroup -Name "cfg-blob" -PrivateEndpointName "pep-$sa-blob" `
  -ResourceGroupName $rgNet -PrivateDnsZoneConfig @(New-AzPrivateDnsZoneConfig -Name "cfg-blob" -PrivateDnsZoneId `
  (New-AzPrivateDnsZone -Name $zoneBlob -ResourceGroupName $rgNet).Id)).PrivateDnsZoneConfigs[0].PrivateDnsZoneId

$zDfsId = (New-AzPrivateDnsZoneGroup -Name "cfg-dfs" -PrivateEndpointName "pep-$sa-dfs" `
  -ResourceGroupName $rgNet -PrivateDnsZoneConfig @(New-AzPrivateDnsZoneConfig -Name "cfg-dfs" -PrivateDnsZoneId `
  (New-AzPrivateDnsZone -Name $zoneDfs -ResourceGroupName $rgNet).Id)).PrivateDnsZoneConfigs[0].PrivateDnsZoneId
```

---

## Step 6 — Disable Public Access to Storage Account
```pwsh
Set-AzStorageAccount `
  -ResourceGroupName $rg `
  -Name $sa `
  -PublicNetworkAccess Disabled | Out-Null
```

---

## ✅ Verification Commands
```pwsh
Get-AzPrivateEndpoint -ResourceGroupName $rgNet | Select Name, Subnet.Name, ProvisioningState
(Get-AzStorageAccount -ResourceGroupName $rg -Name $sa).PublicNetworkAccess
Get-AzPrivateDnsRecordSet -ZoneName $zoneBlob -ResourceGroupName $rgNet -RecordType A
Get-AzPrivateDnsRecordSet -ZoneName $zoneDfs  -ResourceGroupName $rgNet -RecordType A
```

**Expected Output:**
```
Private Endpoints: Succeeded
PublicNetworkAccess: Disabled
DNS Zones contain private IPs
```

✔ **Storage is now private**  
✔ **Traffic stays internal**  
✔ **RBAC controls access — no keys needed**  
✔ **Ready for enterprise workloads**
