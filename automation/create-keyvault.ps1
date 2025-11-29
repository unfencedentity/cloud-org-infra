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

# Azure Key Vault naming rules: 3-24 chars, only alphanumeric and hyphen, must start with a letter
$keyVaultName = $keyVaultName.ToLower()
if ($keyVaultName.Length -lt 3 -or $keyVaultName.Length -gt 24) {
    throw "Key Vault name '$keyVaultName' does not meet length requirements (3-24 characters). Adjust naming convention."
}

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
