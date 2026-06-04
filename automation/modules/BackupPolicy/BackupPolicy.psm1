# BackupPolicy.psm1
# Reusable, idempotent Azure Recovery Services backup policy functions

Set-StrictMode -Version Latest

function Ensure-BackupPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VaultName,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$PolicyName
    )

    try {
        Write-Host "Ensuring backup policy '$PolicyName' exists in vault '$VaultName'..."

        $vault = Get-AzRecoveryServicesVault `
            -Name $VaultName `
            -ResourceGroupName $ResourceGroupName `
            -ErrorAction Stop

        Set-AzRecoveryServicesVaultContext -Vault $vault

        $existingPolicy = Get-AzRecoveryServicesBackupProtectionPolicy `
            -Name $PolicyName `
            -ErrorAction SilentlyContinue

        if ($existingPolicy) {
            Write-Host "Backup policy already exists. Skipping creation."
            return $existingPolicy
        }

        Write-Host "Backup policy not found. Creating daily VM backup policy..."

        $schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject `
            -WorkloadType AzureVM

        $retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject `
            -WorkloadType AzureVM

        $policy = New-AzRecoveryServicesBackupProtectionPolicy `
            -Name $PolicyName `
            -WorkloadType AzureVM `
            -RetentionPolicy $retentionPolicy `
            -SchedulePolicy $schedulePolicy

        Write-Host "Backup policy created successfully: $PolicyName"

        return $policy
    }
    catch {
        throw "[BackupPolicy] Failed to ensure backup policy '$PolicyName' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Ensure-BackupPolicy
