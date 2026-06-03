# Snapshots.psm1
# Reusable, idempotent Azure Managed Disk snapshot functions

Set-StrictMode -Version Latest

function Get-VmOsDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$VmName
    )

    try {
        Write-Host "Retrieving VM '$VmName' from resource group '$ResourceGroupName'..."

        $vm = Get-AzVM `
            -ResourceGroupName $ResourceGroupName `
            -Name $VmName `
            -ErrorAction Stop

        if (-not $vm.StorageProfile.OsDisk.ManagedDisk.Id) {
            throw "VM '$VmName' does not have a managed OS disk."
        }

        return $vm.StorageProfile.OsDisk
    }
    catch {
        throw "[Snapshots] Failed to retrieve OS disk for VM '$VmName' :: $($_.Exception.Message)"
    }
}

function Ensure-DiskSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SnapshotName,
        [Parameter(Mandatory = $true)][string]$ResourceGroupName,
        [Parameter(Mandatory = $true)][string]$Location,
        [Parameter(Mandatory = $true)][string]$SourceDiskId,
        [Parameter()][hashtable]$Tags
    )

    try {
        Write-Host "Ensuring disk snapshot '$SnapshotName' exists..."

        $existingSnapshot = Get-AzSnapshot `
            -ResourceGroupName $ResourceGroupName `
            -SnapshotName $SnapshotName `
            -ErrorAction SilentlyContinue

        if ($existingSnapshot) {
            Write-Host "Snapshot already exists. Skipping creation."
            return $existingSnapshot
        }

        Write-Host "Snapshot not found. Creating snapshot from source disk..."

        $snapshotConfig = New-AzSnapshotConfig `
            -SourceUri $SourceDiskId `
            -Location $Location `
            -CreateOption Copy `
            -Incremental

        $snapshot = New-AzSnapshot `
            -ResourceGroupName $ResourceGroupName `
            -SnapshotName $SnapshotName `
            -Snapshot $snapshotConfig

        if ($Tags) {
            Update-AzTag `
                -ResourceId $snapshot.Id `
                -Tag $Tags `
                -Operation Merge | Out-Null
        }

        Write-Host "Snapshot created successfully: $SnapshotName"

        return $snapshot
    }
    catch {
        throw "[Snapshots] Failed to ensure snapshot '$SnapshotName' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Get-VmOsDisk, Ensure-DiskSnapshot
