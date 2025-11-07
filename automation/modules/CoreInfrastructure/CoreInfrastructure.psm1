# CoreInfrastructure.psm1
# Reusable, idempotent Azure infrastructure provisioning functions

Set-StrictMode -Version Latest

function Ensure-ResourceGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][hashtable]$Tags
    )

    try {
        $existing = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
        if ($existing) {
            if ($Tags) {
                Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null
            }
            Write-Verbose "[RG] Exists: $Name"
            return (Get-AzResourceGroup -Name $Name)
        }

        $created = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
        Write-Verbose "[RG] Created: $Name ($Location)"
        return $created
    }
    catch {
        throw "[RG] Failed for '$Name' in '$Location' :: $($_.Exception.Message)"
    }
}

function Ensure-StorageAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidatePattern('^[a-z0-9]{3,24}$')][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][ValidateSet('Standard_LRS','Standard_GRS','Standard_RAGRS','Standard_ZRS','Premium_LRS')][string]$SkuName = 'Standard_LRS',
        [Parameter()][ValidateSet('StorageV2')][string]$Kind = 'StorageV2',
        [Parameter()][bool]$EnableHierarchicalNamespace = $true,
        [Parameter()][hashtable]$Tags
    )

    try {
        $existing = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction SilentlyContinue

        if ($existing) {
            if ($Tags) {
                Update-AzTag -ResourceId $existing.Id -Tag $Tags -Operation Merge | Out-Null
            }

            # HNS cannot be toggled after creation — warn if mismatch
            if ($EnableHierarchicalNamespace -and -not $existing.EnableHierarchicalNamespace) {
                Write-Warning "[Storage] '$Name' exists without HNS but HNS requested. Recreate storage account if ADLS Gen2 is required."
            }

            Write-Verbose "[Storage] Exists: $Name"
            return (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name)
        }

        $created = New-AzStorageAccount `
            -Name $Name `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -SkuName $SkuName `
            -Kind $Kind `
            -EnableHierarchicalNamespace:$EnableHierarchicalNamespace `
            -Tag $Tags

        Write-Verbose "[Storage] Created: $Name (HNS=$EnableHierarchicalNamespace)"
        return $created
    }
    catch {
        throw "[Storage] Failed for '$Name' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Ensure-ResourceGroup, Ensure-StorageAccount
