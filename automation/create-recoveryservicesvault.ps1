param(
    [string]$Environment = "dev",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = "Stop"

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
