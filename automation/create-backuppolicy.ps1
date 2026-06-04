param(
    [string]$Environment = "dev",
    [string]$Region      = "weu"
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-core-$Environment-$Region"
$vaultName         = "rsv-core-$Environment-$Region"
$policyName        = "policy-vm-daily"

Write-Host "Starting backup policy deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Vault Name: $vaultName"
Write-Host "Policy Name: $policyName"

Import-Module "$PSScriptRoot\modules\BackupPolicy\BackupPolicy.psm1" -Force

Write-Host "Backup Policy module loaded successfully."

$policy = Ensure-BackupPolicy `
    -VaultName $vaultName `
    -ResourceGroupName $resourceGroupName `
    -PolicyName $policyName

Write-Host "Backup Policy deployment completed successfully."
Write-Host "Policy Name: $($policy.Name)"
