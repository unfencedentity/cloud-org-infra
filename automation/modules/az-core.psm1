# az-core.psm1
# Core Azure automation: Resource Groups + Storage Accounts (idempotent, secure defaults)

Set-StrictMode -Version Latest

#region ---------- Resource Group ----------
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
  if (-not $rg) { Write-Host "RG not found: $Name"; return $null }
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
#endregion

#region ---------- Storage Account (helpers) ----------
function Get-CoreStorageAccount {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$ResourceGroupName
  )

  $sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
  if (-not $sa) { Write-Host "Storage not found: $Name"; return $null }
  return $sa
}

function New-CoreStorageContext {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$ResourceGroupName
  )

  $keys = Get-AzStorageAccountKey -Name $Name -ResourceGroupName $ResourceGroupName
  if (-not $keys -or -not $keys[0].Value) { throw "Cannot retrieve storage keys for '$Name'." }
  return (New-AzStorageContext -StorageAccountName $Name -StorageAccountKey $keys[0].Value)
}

function Set-CoreStorageBlobDataProtection {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter()][bool]$EnableVersioning = $true,
    [Parameter()][int]$DeleteRetentionDays = 7
  )

  $ctx = New-CoreStorageContext -Name $Name -ResourceGroupName $ResourceGroupName

  # Enable/ensure versioning & soft delete for blobs
  Set-AzStorageBlobServiceProperty -Context $ctx `
    -IsVersioningEnabled:$EnableVersioning `
    -IsDeleteRetentionPolicyEnabled:$true `
    -DeleteRetentionPolicyInDays $DeleteRetentionDays | Out-Null

  Write-Host "Blob data protection configured: Versioning=$EnableVersioning, DeleteRetentionDays=$DeleteRetentionDays"
}
#endregion

#region ---------- Storage Account (idempotent create + secure defaults) ----------
function New-CoreStorageAccount {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidatePattern('^[a-z0-9]{3,24}$')][string]$Name,
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$Location,

    [Parameter()][ValidateSet('Standard_LRS','Standard_GRS','Standard_RAGRS','Standard_ZRS','Premium_LRS')]
    [string]$SkuName = 'Standard_LRS',

    [Parameter()][bool]$EnableHierarchicalNamespace = $true,   # ADLS Gen2
    [Parameter()][bool]$EnableHttpsTrafficOnly      = $true,
    [Parameter()][string][ValidateSet('TLS1_2')]$MinimumTlsVersion = 'TLS1_2',
    [Parameter()][bool]$AllowBlobPublicAccess      = $false,

    [Parameter()][bool]$EnableBlobVersioning       = $true,
    [Parameter()][ValidateRange(1,365)][int]$BlobDeleteRetentionDays = 7,

    [Parameter()][hashtable]$Tags
  )

  $existing = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
  if ($existing) {
    # Merge/update tags
    if ($Tags) { Update-AzTag -ResourceId $existing.Id -Tag $Tags -Operation Merge | Out-Null }

    # Enforce secure posture (where supported for update)
    Update-AzStorageAccount `
      -ResourceGroupName $ResourceGroupName `
      -Name $Name `
      -EnableHttpsTrafficOnly:$EnableHttpsTrafficOnly `
      -MinimumTlsVersion $MinimumTlsVersion `
      -AllowBlobPublicAccess:$AllowBlobPublicAccess | Out-Null

    # HNS cannot be enabled post-creation; warn if mismatch
    if ($EnableHierarchicalNamespace -and -not $existing.EnableHierarchicalNamespace) {
      Write-Warning "[Storage] '$Name' exists without HNS, but HNS was requested. Recreate if ADLS Gen2 is required."
    }

    # Data protection (Blob)
    Set-CoreStorageBlobDataProtection -Name $Name -ResourceGroupName $ResourceGroupName `
      -EnableVersioning:$EnableBlobVersioning -DeleteRetentionDays $BlobDeleteRetentionDays

    Write-Host "Storage exists: $Name"
    return (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name)
  }

  # Create with secure defaults
  $created = New-AzStorageAccount `
    -Name $Name `
    -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -SkuName $SkuName `
    -Kind StorageV2 `
    -EnableHierarchicalNamespace:$EnableHierarchicalNamespace `
    -EnableHttpsTrafficOnly:$EnableHttpsTrafficOnly `
    -MinimumTlsVersion $MinimumTlsVersion `
    -AllowBlobPublicAccess:$AllowBlobPublicAccess `
    -Tag $Tags

  # Configure Blob data protection after creation
  Set-CoreStorageBlobDataProtection -Name $Name -ResourceGroupName $ResourceGroupName `
    -EnableVersioning:$EnableBlobVersioning -DeleteRetentionDays $BlobDeleteRetentionDays

  Write-Host "Storage created: $Name"
  return $created
}

function Set-CoreStorageAccountTags {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][hashtable]$Tags
  )

  $sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue
  if (-not $sa) { throw "Storage '$Name' not found in RG '$ResourceGroupName'." }

  Update-AzTag -ResourceId $sa.Id -Tag $Tags -Operation Merge | Out-Null
  Write-Host "Storage tags merged: $Name"
  return (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name)
}
#endregion

Export-ModuleMember -Function `
  New-CoreResourceGroup, Get-CoreResourceGroup, Set-CoreResourceGroupTags, `
  Get-CoreStorageAccount, New-CoreStorageContext, Set-CoreStorageBlobDataProtection, `
  New-CoreStorageAccount, Set-CoreStorageAccountTags
