# Azure Core Utility Module
# Provides idempotent create operations for cloud infrastructure components

function New-CoreResourceGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][hashtable]$Tags
    )

    $existing = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue
    if ($existing) {
        if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
        Write-Host "RG exists: $Name"
        return $existing
    }

    $result = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
    Write-Host "RG created: $Name"
    return $result
}

function New-CoreStorageAccount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][hashtable]$Tags
    )

    $existing = Get-AzStorageAccount -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Storage exists: $Name"
        return $existing
    }

    $result = New-AzStorageAccount `
        -Name $Name `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -SkuName Standard_LRS `
        -Kind StorageV2 `
        -EnableHierarchicalNamespace $true `
        -AllowBlobPublicAccess $false `
        -MinimumTlsVersion TLS1_2 `
        -Tag $Tags

    Write-Host "Storage created: $Name"
    return $result
}

Export-ModuleMember -Function *-Core*
