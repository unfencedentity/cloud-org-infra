<#
.SYNOPSIS
    Deletes an Azure environment resource group and all resources inside it.

.DESCRIPTION
    This script removes the target Azure Resource Group for a specific application,
    environment, and region.

    Use this script carefully. Removing a Resource Group deletes all contained resources.

.EXAMPLE
    ./cleanup.ps1 `
        -Environment dev `
        -App core `
        -Region weu `
        -Location westeurope

.EXAMPLE
    ./cleanup.ps1 `
        -Environment dev `
        -App core `
        -Region weu `
        -Location westeurope `
        -Force
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet("dev", "test", "prod")]
    [string]$Environment = "dev",

    [string]$App = "core",

    [ValidateSet("weu", "neu", "eus", "wus")]
    [string]$Region = "weu",

    [string]$Location = "westeurope",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"
$coreVnetName = "vnet-$App-$Environment-$Region"
$hubVnetName = "vnet-hub-$Environment-$Region"
$coreToHubPeeringName = "peer-core-to-hub"
$hubToCorePeeringName = "peer-hub-to-core"

Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "Azure Environment Cleanup" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "Environment    : $Environment"
Write-Host "Application    : $App"
Write-Host "Region         : $Region"
Write-Host "Location       : $Location"
Write-Host "Resource Group : $resourceGroupName"
Write-Host ""

Write-Warning "This operation will delete the Resource Group '$resourceGroupName' and all resources inside it."

if (-not $Force) {
    $confirmation = Read-Host "Type 'YES' to confirm deletion"

    if ($confirmation -ne "YES") {
        Write-Host "Cleanup cancelled."
        exit 0
    }
}

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $resourceGroup) {
    Write-Host "Resource Group not found: $resourceGroupName"
    exit 0
}

function Remove-VNetPeeringIfExists {
    param(
        [Parameter(Mandatory = $true)][string]$LocalVNetName,
        [Parameter(Mandatory = $true)][string]$PeeringName
    )

    $localVnet = Get-AzVirtualNetwork `
        -Name $LocalVNetName `
        -ResourceGroupName $resourceGroupName `
        -ErrorAction SilentlyContinue

    if (-not $localVnet) {
        Write-Host "VNet '$LocalVNetName' not found. Skipping peering cleanup for '$PeeringName'."
        return
    }

    $peering = Get-AzVirtualNetworkPeering `
        -Name $PeeringName `
        -VirtualNetworkName $LocalVNetName `
        -ResourceGroupName $resourceGroupName `
        -ErrorAction SilentlyContinue

    if (-not $peering) {
        Write-Host "Peering '$PeeringName' not found on VNet '$LocalVNetName'."
        return
    }

    if ($PSCmdlet.ShouldProcess("VNet peering '$PeeringName' on '$LocalVNetName'", "Remove")) {
        Write-Host "Removing VNet peering '$PeeringName' on VNet '$LocalVNetName'..." -ForegroundColor Yellow

        Remove-AzVirtualNetworkPeering `
            -Name $PeeringName `
            -VirtualNetworkName $LocalVNetName `
            -ResourceGroupName $resourceGroupName `
            -Force

        Write-Host "Removed VNet peering '$PeeringName' on VNet '$LocalVNetName'."
    }
}

Write-Host "Preparing network teardown by removing VNet peerings..."
Remove-VNetPeeringIfExists -LocalVNetName $coreVnetName -PeeringName $coreToHubPeeringName
Remove-VNetPeeringIfExists -LocalVNetName $hubVnetName -PeeringName $hubToCorePeeringName

if ($PSCmdlet.ShouldProcess($resourceGroupName, "Delete Resource Group and all contained resources")) {
    Write-Host "Starting deletion for Resource Group: $resourceGroupName" -ForegroundColor Yellow

    Remove-AzResourceGroup `
        -Name $resourceGroupName `
        -Force `
        -AsJob | Out-Null

    Write-Host "Deletion started as a background job."
    Write-Host "Resource Group: $resourceGroupName"
}

Write-Host ""
Write-Host "Cleanup command completed."
