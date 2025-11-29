[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$Sku = "Standard",

    # Optional: allows extending the default tag set
    [Parameter(Mandatory = $false)][hashtable]$AdditionalTags
)

$ErrorActionPreference = "Stop"

# Naming conventions
$resourceGroupName = "rg-$App-$Environment-$Region"
$keyVaultName      = "kv-$App-$Environment-$Region"

# Generate deterministic globally-unique Key Vault name
$subscriptionId = (Get-AzContext).Subscription.Id

$baseString = "$subscriptionId-$App-$Environment-$Region"

# Compute short stable hash
$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)
$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

# kv + app + env + region + hash (must only contain letters, numbers)
$keyVaultName = "kv$App$Environment$Region$hash".ToLower()
$keyVaultName = $keyVaultName.Replace("-", "")


# Default tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Merge any additional tags into the default tag set
if ($AdditionalTags) {
    foreach ($key in $AdditionalTags.Keys) {
        $tags[$key] = $AdditionalTags[$key]
    }
}

# Validate Resource Group
$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$resourceGroupName' does not exist. Run create-rg.ps1 first."
}

# Check if Key Vault already exists
$existingKv = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($existingKv) {
    Write-Host ("Key Vault '{0}' already exists in resource group '{1}'. Skipping create." -f `
        $keyVaultName, $resourceGroupName)
    return $existingKv
}

# Supports -WhatIf / -Confirm
if (-not $PSCmdlet.ShouldProcess("Key Vault '$keyVaultName' in '$Location'", "Create")) {
    return
}

Write-Host ("Creating Key Vault '{0}' in resource group '{1}' (Location: {2}, Sku: {3})..." -f `
    $keyVaultName, $resourceGroupName, $Location, $Sku)

$kv = New-AzKeyVault `
    -Name              $keyVaultName `
    -ResourceGroupName $resourceGroupName `
    -Location          $Location `
    -Sku               $Sku `
    -Tag               $tags

Write-Host ("Key Vault '{0}' created." -f $keyVaultName)

return $kv
