# VmBackup.psm1
# Reusable, idempotent Azure VM backup functions

Set-StrictMode -Version Latest

function Enable-VmBackupProtection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VaultName,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter(Mandatory)][string]$VmName
    )

    try {
        Write-Host "Retrieving Recovery Services Vault..."

        $vault = Get-AzRecoveryServicesVault `
            -Name $VaultName `
            -ResourceGroupName $ResourceGroupName `
            -ErrorAction Stop

        Set-AzRecoveryServicesVaultContext -Vault $vault

        Write-Host "Retrieving backup policy..."

        $policy = Get-AzRecoveryServicesBackupProtectionPolicy `
            -Name $PolicyName `
            -ErrorAction Stop

        $container = Get-AzRecoveryServicesBackupContainer `
            -ContainerType AzureVM `
            -FriendlyName $VmName `
            -ErrorAction SilentlyContinue

        if ($container) {

            $existingItem = Get-AzRecoveryServicesBackupItem `
                -Container $container `
                -WorkloadType AzureVM `
                -ErrorAction SilentlyContinue

            if ($existingItem) {
                Write-Host "VM backup is already enabled."
                return $existingItem
            }
        }

        Write-Host "Enabling VM backup protection..."

        $vm = Get-AzVM `
            -ResourceGroupName $ResourceGroupName `
            -Name $VmName `
            -ErrorAction Stop

        $backupItem = Enable-AzRecoveryServicesBackupProtection `
            -Policy $policy `
            -Name $vm.Name `
            -ResourceGroupName $ResourceGroupName

        Write-Host "VM backup protection enabled successfully."

        return $backupItem
    }
    catch {
        throw "[VmBackup] Failed to enable backup protection for '$VmName' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Enable-VmBackupProtection
