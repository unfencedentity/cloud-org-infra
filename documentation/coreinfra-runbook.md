# Core Infrastructure Runbook

This runbook explains how to deploy and verify the **core infrastructure** for the `cloud-org-infra` project using PowerShell and the `CoreInfrastructure` module.

---

## 1. Prerequisites

Before running any commands, make sure you have:

- An active Azure subscription  
- PowerShell 7+ installed  
- Az PowerShell modules installed  
- This repository cloned locally, for example:

```pwsh
C:\repos\cloud-org-infra
```

---

## 2. Login to Azure

From a PowerShell session:

```pwsh
Connect-AzAccount
```

Confirm the active context:

```pwsh
Get-AzContext
```

You should see your subscription and tenant correctly loaded.

---

## 3. Run Core Infrastructure Deployment

Navigate to the `automation` folder and run the core infrastructure entrypoint:

```pwsh
Set-Location C:\repos\cloud-org-infra\automation
.\create-coreinfra.ps1
```

By default, this will:

- Create or ensure the **Resource Group**: `rg-dev-weu`
- Create or ensure the **Storage Account (ADLS Gen2)**: `stdevweu2401`
- Apply standard tags:
  - `owner = lucian`
  - `env = dev`
  - `app = core`

The script is **idempotent** — you can safely run it multiple times.  
If resources already exist, they are reused.

---

## 4. Verification Commands

After the script runs, verify that the core resources are in place.

### 4.1. Check the Resource Group

```pwsh
Get-AzResourceGroup -Name "rg-dev-weu"
```

### 4.2. Check the Storage Account

```pwsh
Get-AzStorageAccount -ResourceGroupName "rg-dev-weu" -Name "stdevweu2401"
```

### 4.3. Confirm ADLS Gen2 (Hierarchical Namespace)

```pwsh
(Get-AzStorageAccount -ResourceGroupName "rg-dev-weu" -Name "stdevweu2401").EnableHierarchicalNamespace
```

Expected:

```
True
```

---

## 5. Behavior and Conventions

- This runbook covers **core infrastructure**:
  - Resource Group
  - ADLS Gen2 Storage Account
- Naming convention:
  - Resource Group: `rg-<env>-weu`
  - Storage Account: `st<env>weu2401`
- Tags used:
  - `owner`
  - `env`
  - `app`

---

## 6. Next Steps (Future Runbooks)

Planned future runbooks:

- Network Infrastructure (VNet, subnets, NSGs)  
- Private Endpoints & Private DNS  
- Application Layer (App Service, Managed Identity)  
- CI/CD (GitHub Actions OIDC deployment)

This file serves as a reference for quickly bootstrapping the core environment for `cloud-org-infra`.
