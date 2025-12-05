ADLS Gen2 Storage Quickstart (PowerShell)

This document explains how to provision an ADLS Gen2–enabled Storage Account using the automation script create-storage.ps1. It also covers naming, tagging, container creation, and basic usage.

--------------------------------------------------------------------
1. Overview
--------------------------------------------------------------------
The provisioning script performs the following actions:
- Generates a globally unique Storage Account name using a deterministic SHA256 hash.
- Creates a Storage Account with Hierarchical Namespace (ADLS Gen2) enabled.
- Applies standard tags: environment, app, region, owner.
- Creates default containers: logs, apps, data.
- Returns the Storage Account object for downstream automation.

Naming pattern:
st{app}{environment}{region}{hash}
Example: stcoredevweu3fa91c

--------------------------------------------------------------------
2. Prerequisites
--------------------------------------------------------------------
Login and select a subscription:

Connect-AzAccount -DeviceCode
Set-AzContext -Subscription (
    Get-AzSubscription |
    Where-Object {$_.State -eq "Enabled"} |
    Select-Object -First 1 -ExpandProperty Id
)

Modules required:
Az.Accounts, Az.Resources, Az.Storage

The Resource Group must already exist:
rg-{app}-{environment}-{region}

--------------------------------------------------------------------
3. Provisioning the Storage Account
--------------------------------------------------------------------
Run the automation script:

./automation/create-storage.ps1 `
    -Environment dev `
    -App core `
    -Region weu `
    -Location westeurope

The script performs the following automatically:
1. Generates a deterministic storage name.
2. Validates the Resource Group.
3. Creates the Storage Account if missing.
4. Ensures default containers: logs, apps, data.

Example output:
Creating storage account 'stcoredevweu9a3d11'...
Storage account created.
Container 'logs' created.
Container 'apps' created.
Container 'data' created.

--------------------------------------------------------------------
4. Tagging Standards
--------------------------------------------------------------------
Tags applied to the Storage Account:

environment = dev
app         = core
region      = weu
owner       = cloud-org-infra

Tags are used for diagnostics routing, automation filters, cost allocation, and lifecycle management.

--------------------------------------------------------------------
5. Working With the Storage Account
--------------------------------------------------------------------
Retrieve the Storage Account:

$sa = Get-AzStorageAccount `
    -ResourceGroupName "rg-core-dev-weu" `
    -Name "stcoredevweuXXXXX"

Create an additional container:

New-AzStorageContainer `
    -Context $sa.Context `
    -Name "raw" `
    -Permission Off

Upload a file:

Set-AzStorageBlobContent `
    -Context $sa.Context `
    -Container "raw" `
    -File "C:\Temp\sample.json" `
    -Blob "sandbox/sample.json"

--------------------------------------------------------------------
6. Cleanup (optional)
--------------------------------------------------------------------
Remove-AzStorageAccount `
    -Name $sa.StorageAccountName `
    -ResourceGroupName $sa.ResourceGroupName `
    -Force

--------------------------------------------------------------------
7. References
--------------------------------------------------------------------
Automation script: automation/create-storage.ps1
Naming standards: documentation/fundamentals/naming.md
Diagnostics integration: automation/create-diagnostics.ps1

--------------------------------------------------------------------
Status: Production-ready
Owner: cloud-org-infra
