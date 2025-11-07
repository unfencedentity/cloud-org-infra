# PowerShell Fundamentals (Cloud-focused)

PowerShell works with **objects**, not plain text.  
This makes it ideal for Azure automation, CI/CD pipelines, and infrastructure-as-code.

---

## 1) Objects, not text

Every command (cmdlet) returns **objects** with properties and methods.

Examples:

```powershell
Get-Service
Get-Service | Get-Member
Get-Service | Select Name, Status | Sort-Object Status
```

`Get-Member` is how we inspect the structure of an object.

---

## 2) Cmdlet Structure (Verb-Noun)

PowerShell commands follow a predictable naming pattern:

```powershell
New-AzResourceGroup
Get-AzStorageAccount
Set-AzResourceGroup
Remove-AzRoleAssignment
```

This makes scripts readable and consistent.

---

## 3) Pipeline passes objects

The pipe `|` passes **objects**, not text.

```powershell
Get-Process |
  Where-Object { $_.CPU -gt 1 } |
  Select Name, CPU |
  Sort-Object CPU -Descending
```

You are filtering **object properties**, not text lines.

---

## 4) Variables, Arrays, Hashtables

```powershell
# Variable
$env = "dev"

# Array
$names = @("one","two","three")
$names[0]   # one

# Hashtable (key/value)
$tags = @{ env="dev"; app="core"; owner="lucian" }
$tags.app   # core
```

Hashtables are heavily used for tagging and parameterized deployments.

---

## 5) Discoverability (how to learn any command)

```powershell
Get-Command *ResourceGroup*
Get-Help New-AzStorageAccount -Examples
```

You do **not** memorize cmdlets — you learn how to **search**.

---

## 6) Idempotent deployment pattern

Ensures **running deployments multiple times does NOT duplicate resources**.

```powershell
param([string]$Name,[string]$Location,[hashtable]$Tags)

$rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

if ($rg) {
    if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
    Write-Host "RG exists: $Name"
} else {
    New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags | Out-Null
    Write-Host "RG created: $Name"
}
```

---

## 7) Professional function structure

```powershell
function New-CoreResourceGroup {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Location,
    [Parameter()][hashtable]$Tags
  )

  $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

  if ($rg) {
    if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
    Write-Host "RG exists: $Name"
    return $rg
  }

  $created = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
  Write-Host "RG created: $Name"
  return $created
}
```

This is the recommended structure for infrastructure modules.

---

## 8) Practical Azure snippets

```powershell
Get-AzContext
Get-AzSubscription | Select Name, Id

New-AzStorageAccount -Name "stcoredevweu12345" `
  -ResourceGroupName "rg-core-dev-weu" `
  -Location "westeurope" -SkuName Standard_LRS `
  -Kind StorageV2 -EnableHierarchicalNamespace $true
```

---

## 9) Mini Practice

```powershell
# A) Inspect object structure
Get-Process | Get-Member

# B) Filter and select properties
Get-Service | Where-Object { $_.Status -eq "Running" } | Select Name, Status

# C) Hashtable field access
$tags = @{ env="dev"; app="core" }; $tags.env

# D) Idempotent resource group creation
$rgName="rg-dev-weu"; $loc="westeurope"
if (-not(Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $rgName -Location $loc | Out-Null
}
Get-AzResourceGroup -Name $rgName
```

---

## 10) Next Steps

- Convert repeated automation logic into **PowerShell modules** (`.psm1`)
- Use **parameter files** (`.psd1`) for environment differences
- Apply this structure to:
  - VNet
  - Storage
  - Key Vault
  - Identity (RBAC)

---

## 11) Quick Cheat-Sheet

```powershell
# Inspect type structure
Get-Service | Get-Member

# Pipeline filtering + projection
Get-Process |
  Where-Object { $_.CPU -gt 1 } |
  Select Name, CPU |
  Sort-Object CPU -Descending

# Arrays
$names = @("one","two","three")
$names[1]

# Hashtables
$tags = @{ env="dev"; app="core" }
$tags.app

# Ensure resource group idempotently
Ensure-ResourceGroup -Name "rg-dev-weu" -Location "westeurope" -Tags @{ env="dev"; app="core" }
```

---
