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
    ,
    [Parameter(Mandatory = $true)]
    [string]$RootCertificatePath
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

    $rootCertBase64 = [System.Convert]::ToBase64String(
    [System.IO.File]::ReadAllBytes(
    $RootCertificatePath    )
)

Ensure-VirtualNetworkGateway `
    -ResourceGroupName $ResourceGroupName `
    -GatewayName "vpngw-core-dev-weu" `
    -Location $Location `
    -VirtualNetworkName $VirtualNetworkName `
    -PublicIpName $PublicIpName
    
    Ensure-PointToSiteConfiguration `
    -ResourceGroupName "rg-core-dev-weu" `
    -GatewayName "vpngw-core-dev-weu" `
    -VpnClientAddressPool "172.16.250.0/24" `
    -RootCertificateName "cloud-org-infra-root-cert" `
    -RootCertificatePublicData $rootCertBase64
