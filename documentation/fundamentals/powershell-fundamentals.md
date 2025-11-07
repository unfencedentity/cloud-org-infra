# PowerShell Fundamentals (Cloud-focused)

PowerShell is a programming language and shell that works with **objects**, not plain text. That is what makes it ideal for Azure automation and CI/CD.

---

## 1) Objects, not text

Every command (cmdlet) returns **objects** with properties and methods.

Examples:

Get-Service
Get-Service | Get-Member
Get-Service | Select Name, Status | Sort-Object Status

`Get-Member` is how we inspect the structure of an object.

---

## 2) Cmdlet structure: Verb-Noun

PowerShell commands follow this pattern:

New-AzResourceGroup
Get-AzStorageAccount
Set-AzResourceGroup
Remove-AzRoleAssignment

This makes scripts readable and predictable.

---

## 3) Pipeline passes objects

The pipe `|` sends objects, not strings:

Get-Process |
  Where-Object { $_.CPU -gt 1 } |
  Select Name, CPU |
  Sort-Object CPU -Descending

This is fundamentally different from Bash or CMD.
You are filtering *object properties*, not text lines.

---

## 4) Variables, Arrays, Hashtables

# Variable
$env = "dev"

# Array
$names = @("one","two","three")
$names[0]   # one

# Hashtable (key/value)
$tags = @{ env="dev"; app="core"; owner="lucian" }
$tags.app   # "core"

Hashtables are heavily used for **tags**, **parameters**, and **resource definitions**.

---

## 5) Discoverability (how to learn any command)

Get-Command *ResourceGroup*
Get-Help New-AzStorageAccount -Examples

You do **not** memorize cmdlets.
You learn **how to search** for them.

---

## 6) Idempotent pattern (critical for cloud deploys)

We use this pattern in the repo to avoid duplicates on re-run.

param([string]$Name,[string]$Location,[hashtable]$Tags)

$rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

if ($rg) {
    if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
    Write-Host "RG exists: $Name"
} else {
    New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags | Out-Null
    Write-Host "RG created: $Name"
}

This ensures multiple deployments give one consistent state.

---

## 7) Professional function pattern

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

This is how our infrastructure scripts should be structured.

---

## 8) Practical Azure snippets (copy-ready)

Get-AzContext
Get-AzSubscription | Select Name, Id

New-AzStorageAccount -Name "stcoredevweu12345" `
  -ResourceGroupName "rg-core-dev-weu" `
  -Location "westeurope" -SkuName Standard_LRS `
  -Kind StorageV2 -EnableHierarchicalNamespace $true

---

## 9) Mini practice (5 minutes)

A) Explore:
Get-Process | Get-Member

B) Filter:
Get-Service | Where-Object { $_.Status -eq "Running" } | Select Name, Status

C) Hashtable:
$tags = @{ env="dev"; app="core" }; $tags.env

D) Idempotent RG:
$rgName="rg-dev-weu"; $loc="westeurope"
if (-not(Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $rgName -Location $loc | Out-Null
}
Get-AzResourceGroup -Name $rgName

---

## 10) Next steps in this repo

- We will convert repeated logic into **modules** (`.psm1`)
- We will introduce **environment parameter files** (`.psd1`)
- We will apply this to VNet, Storage, Key Vault, Identity

Updating...

You now have the base language skills needed to build reusable cloud automation.
