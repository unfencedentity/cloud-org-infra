# az-core.psm1
# Core utilities for Azure resource groups (idempotent create + read + tag update)

function New-CoreResourceGroup {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Location,
    [Parameter()][hashtable]$Tags
  )

  $existing = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
  if ($existing) {
    if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
    Write-Host "RG exists: $Name"
    return (Get-AzResourceGroup -Name $Name)
  }

  $result = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
  Write-Host "RG created: $Name"
  return $result
}

function Get-CoreResourceGroup {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Name)

  $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
  if (-not $rg) {
    Write-Host "RG not found: $Name"
    return $null
  }
  return $rg
}

function Set-CoreResourceGroupTags {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][hashtable]$Tags
  )

  $rg = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
  if (-not $rg) { throw "Resource group '$Name' not found." }

  $updated = Set-AzResourceGroup -Name $Name -Tag $Tags
  Write-Host "RG tags updated: $Name"
  return $updated
}

Export-ModuleMember -Function New-CoreResourceGroup, Get-CoreResourceGroup, Set-CoreResourceGroupTags
