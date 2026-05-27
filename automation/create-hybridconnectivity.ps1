param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VirtualNetworkName,

    [Parameter(Mandatory = $true)]
    [string]$GatewaySubnetAddressPrefix,

    [Parameter(Mandatory = $true)]
    [string]$PublicIpName,

    [Parameter(Mandatory = $true)]
    [string]$Location
)

$modulePath = Join-Path $PSScriptRoot "modules/HybridConnectivity/HybridConnectivity.psm1"

Import-Module $modulePath -Force

Ensure-GatewaySubnet `
    -ResourceGroupName $ResourceGroupName `
    -VirtualNetworkName $VirtualNetworkName `
    -GatewaySubnetAddressPrefix $GatewaySubnetAddressPrefix

Ensure-VpnGatewayPublicIp `
    -ResourceGroupName $ResourceGroupName `
    -PublicIpName $PublicIpName `
    -Location $Location
