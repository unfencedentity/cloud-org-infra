param(
    [string]$Environment = "dev",
    [string]$Region,
    [string]$Location
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\DeploymentDefaults.ps1"

$deploymentContext = Resolve-DeploymentRegionLocation -Region $Region -Location $Location
$Region = $deploymentContext.Region
$Location = $deploymentContext.Location

$resourceGroupName = "rg-core-$Environment-$Region"
$rsvName           = "rsv-core-$Environment-$Region"

$tags = @{
    environment = $Environment
    region      = $Region
    component   = "backup"
    purpose     = "disaster-recovery"
}

Write-Host "Starting Recovery Services Vault deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Vault Name: $rsvName"
Write-Host "Location: $Location"

Import-Module "$PSScriptRoot\modules\RecoveryServicesVault\RecoveryServicesVault.psm1" -Force

Write-Host "Recovery Services Vault module loaded successfully."

$vault = Ensure-RecoveryServicesVault `
    -Name $rsvName `
    -ResourceGroupName $resourceGroupName `
    -Location $Location `
    -Tags $tags

Write-Host "Recovery Services Vault deployment completed successfully."
Write-Host "Vault Name: $($vault.Name)"
Write-Host "Vault ID: $($vault.ID)"
