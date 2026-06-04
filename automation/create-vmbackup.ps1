param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu"
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-core-$Environment-$Region"
$vaultName         = "rsv-$App-$Environment-$Region"
$policyName        = "policy-vm-daily"
$vmName            = "vm-$Environment-$App-$Region-01"

Write-Host "Starting VM backup deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Vault Name: $vaultName"
Write-Host "Policy Name: $policyName"
Write-Host "VM Name: $vmName"

Import-Module "$PSScriptRoot\modules\VmBackup\VmBackup.psm1" -Force

Write-Host "VM Backup module loaded successfully."

$backupItem = Enable-VmBackupProtection `
    -VaultName $vaultName `
    -ResourceGroupName $resourceGroupName `
    -PolicyName $policyName `
    -VmName $vmName

Write-Host "VM backup deployment completed successfully."
Write-Host "Protected VM: $vmName"
