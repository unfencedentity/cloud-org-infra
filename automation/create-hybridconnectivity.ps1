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
    [Parameter(Mandatory = $false)]
    [string]$GatewayName,

    [Parameter(Mandatory = $true)]
    [string]$RootCertificatePath
)

$modulePath = Join-Path $PSScriptRoot "modules/HybridConnectivity/HybridConnectivity.psm1"

Import-Module $modulePath -Force

if ([string]::IsNullOrWhiteSpace($GatewayName)) {
    if ($PublicIpName -like "pip-*") {
        $GatewayName = $PublicIpName.Substring(4)
    }
    else {
        $GatewayName = "vpngw-core-dev-deu"
    }
}

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
    -GatewayName $GatewayName `
    -Location $Location `
    -VirtualNetworkName $VirtualNetworkName `
    -PublicIpName $PublicIpName
    
Ensure-PointToSiteConfiguration `
    -ResourceGroupName $ResourceGroupName `
    -GatewayName $GatewayName `
    -VpnClientAddressPool "172.16.250.0/24" `
    -RootCertificateName "cloud-org-infra-root-cert" `
    -RootCertificatePublicData $rootCertBase64
