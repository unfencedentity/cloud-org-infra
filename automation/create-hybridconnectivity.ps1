param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VirtualNetworkName,

    [Parameter(Mandatory = $true)]
    [string]$GatewaySubnetAddressPrefix
)

$modulePath = Join-Path $PSScriptRoot "modules/HybridConnectivity/HybridConnectivity.psm1"

Import-Module $modulePath -Force

Ensure-GatewaySubnet `
    -ResourceGroupName $ResourceGroupName `
    -VirtualNetworkName $VirtualNetworkName `
    -GatewaySubnetAddressPrefix $GatewaySubnetAddressPrefix
