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

    function Test-CoreStorageName {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name)
    if ($Name -notmatch '^[a-z0-9]{3,24}$') {
        throw "Storage Account name must be 3-24 characters, lowercase+digits only. Given: '$Name'"
    }
}

function Get-CoreStorageAccount {
    [CmdletBinding()] param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName
    )
    Test-CoreStorageName -Name $Name
    try {
        return Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name -ErrorAction Stop
    } catch { return $null }
}

function New-CoreStorageAccount {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [string]$Location,
        [hashtable]$Tags,
        [switch]$EnableHierarchicalNamespace
    )

    Test-CoreStorageName -Name $Name

    if (-not $Location) {
        $Location = (Get-AzResourceGroup -Name $ResourceGroupName).Location
    }

    $existing = Get-CoreStorageAccount -Name $Name -ResourceGroupName $ResourceGroupName
    if ($existing) {
        Write-Host "Storage exists: $Name"
        return $existing
    }

    Write-Host "Creating Storage: $Name (ADLS Gen2=$EnableHierarchicalNamespace)"
    return New-AzStorageAccount `
        -Name $Name `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -SkuName Standard_LRS `
        -Kind StorageV2 `
        -EnableHierarchicalNamespace:($EnableHierarchicalNamespace.IsPresent) `
        -Tags $Tags
}

function Set-CoreStorageContext {
    [CmdletBinding()] param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ResourceGroupName
    )
    $sa = Get-CoreStorageAccount -Name $Name -ResourceGroupName $ResourceGroupName
    $ctx = New-AzStorageContext -StorageAccountName $sa.StorageAccountName -UseConnectedAccount
    Set-AzCurrentStorageAccount -ResourceGroupName $ResourceGroupName -Name $Name | Out-Null
    Set-Variable -Name CoreStorageContext -Scope Script -Value $ctx -Force
    return $ctx
}

}

Export-ModuleMember -Function *-Core*
