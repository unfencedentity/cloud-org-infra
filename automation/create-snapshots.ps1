param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-core-$Environment-$Region"
$vmName            = "vm-$Environment-$App-$Region-01"
$snapshotName      = "snap-$Environment-$App-$Region-osdisk-01"

$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    component   = "snapshots"
    purpose     = "disaster-recovery"
}

Write-Host "Starting snapshot deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "VM Name: $vmName"
Write-Host "Snapshot Name: $snapshotName"
Write-Host "Location: $Location"

Import-Module "$PSScriptRoot\modules\Snapshots\Snapshots.psm1" -Force

$osDisk = Get-VmOsDisk `
    -ResourceGroupName $resourceGroupName `
    -VmName $vmName

Write-Host "OS Disk found: $($osDisk.Name)"
Write-Host "OS Disk ID: $($osDisk.ManagedDisk.Id)"

$snapshot = Ensure-DiskSnapshot `
    -SnapshotName $snapshotName `
    -ResourceGroupName $resourceGroupName `
    -Location $Location `
    -SourceDiskId $osDisk.ManagedDisk.Id `
    -Tags $tags

Write-Host "Snapshot deployment completed successfully."
Write-Host "Snapshot Name: $($snapshot.Name)"
Write-Host "Snapshot ID: $($snapshot.Id)"
