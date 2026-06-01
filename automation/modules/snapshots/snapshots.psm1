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

Export-ModuleMember -Function Get-VmOsDisk
