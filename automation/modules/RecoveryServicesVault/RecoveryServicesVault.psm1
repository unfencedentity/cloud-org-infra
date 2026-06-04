# RecoveryServicesVault.psm1
# Reusable, idempotent Recovery Services Vault functions

Set-StrictMode -Version Latest

function Ensure-RecoveryServicesVault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][hashtable]$Tags
    )

    try {
        $existingVault = Get-AzRecoveryServicesVault `
            -Name $Name `
            -ResourceGroupName $ResourceGroupName `
            -ErrorAction SilentlyContinue

        if ($existingVault) {

            if ($Tags) {
                Update-AzTag `
                    -ResourceId $existingVault.ID `
                    -Tag $Tags `
                    -Operation Merge | Out-Null
            }

            Write-Host "Recovery Services Vault already exists."
            return $existingVault
        }

        Write-Host "Creating Recovery Services Vault..."

        $vault = New-AzRecoveryServicesVault `
            -Name $Name `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location

        if ($Tags) {
            Update-AzTag `
                -ResourceId $vault.ID `
                -Tag $Tags `
                -Operation Merge | Out-Null
        }

        return $vault
    }
    catch {
        throw "[RecoveryServicesVault] Failed for '$Name' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Ensure-RecoveryServicesVault
