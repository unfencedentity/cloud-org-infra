<#
.SYNOPSIS
  Creates or ensures an Azure Key Vault for the environment.

.DESCRIPTION
  This script creates an Azure Key Vault in the specified resource group and region,
  following the naming and tagging conventions used in cloud-org-infra.

  It is idempotent: running it multiple times is safe.
#>

[CmdletBinding()]
param(
    [string]$Environment        = "dev",
    [string]$Location           = "westeurope",
    [string]$ResourceGroupName  = "rg-dev-weu",
    [string]$Owner              = "lucian"
)

Write-Host "=== Key Vault deployment for environment: $Environment ===" -ForegroundColor Cyan

# Build Key Vault name (simple pattern, must be globally unique, lowercase, 3-24 chars)
# Adjust if you already picked a specific name
$kvName = "kv-$Environment-weu-core"

# Tags
$tags = @{
    owner = $Owner
    env   = $Environment
    app   = "core"
}


# 1. Ensure Resource Group exists (simple check, assumes rg already created by coreinfra)
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource Group '$ResourceGroupName' not found. Creating it..." -ForegroundColor Yellow
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $tags
} else {
    Write-Host "Resource Group '$ResourceGroupName' already exists." -ForegroundColor Yellow
}

# 2. Check if Key Vault already exists
$existingKv = Get-AzKeyVault -VaultName $kvName -ErrorAction SilentlyContinue

if ($existingKv) {
    Write-Host "Key Vault '$kvName' already exists in RG '$ResourceGroupName'." -ForegroundColor Yellow
}
else {
    Write-Host "Creating Key Vault '$kvName' in RG '$ResourceGroupName'..." -ForegroundColor Green

    # NOTE:
    # -EnablePurgeProtection and soft delete are recommended in production.
    # For learning, we enable soft delete and optionally purge protection.
    $kv = New-AzKeyVault `
        -Name $kvName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Sku Standard `
        -EnabledForDeployment $false `
        -EnabledForTemplateDeployment $false `
        -EnabledForDiskEncryption $false `
        -EnableRbacAuthorization `
        -Tag $tags

    Write-Host "Key Vault '$kvName' created." -ForegroundColor Green
}

# 3. Output current KV state
$kvState = Get-AzKeyVault -VaultName $kvName -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Key Vault Summary ===" -ForegroundColor Cyan
Write-Host "Name    : $($kvState.VaultName)"
Write-Host "RG      : $($kvState.ResourceGroupName)"
Write-Host "Location: $($kvState.Location)"
Write-Host "Sku     : $($kvState.Sku)" 
Write-Host "RBAC    : Enabled (EnableRbacAuthorization = $($kvState.EnableRbacAuthorization))"
Write-Host "Tags    : $($kvState.Tags | Out-String)"
Write-Host ""
Write-Host "=== Key Vault deployment complete ===" -ForegroundColor Green

