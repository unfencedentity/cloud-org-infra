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
    return $existing
  }

  $result = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
  Write-Host "RG created: $Name"
  return $result
}

