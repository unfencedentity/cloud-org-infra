function Ensure-GatewaySubnet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$VirtualNetworkName,

        [Parameter(Mandatory = $true)]
        [string]$GatewaySubnetAddressPrefix
    )

    Write-Host "Ensuring GatewaySubnet exists in virtual network '$VirtualNetworkName'..."

    if ([string]::IsNullOrWhiteSpace($GatewaySubnetAddressPrefix)) {
        throw "GatewaySubnetAddressPrefix cannot be empty."
    }

    if ($GatewaySubnetAddressPrefix -notmatch '^\d{1,3}(\.\d{1,3}){3}\/\d{1,2}$') {
        throw "GatewaySubnetAddressPrefix must be a valid CIDR block, for example '10.10.255.0/27'."
    }

    $prefixLength = [int]($GatewaySubnetAddressPrefix.Split('/')[1])

    if ($prefixLength -gt 27) {
        throw "GatewaySubnetAddressPrefix should be /27 or larger for VPN Gateway scenarios."
    }

    $virtualNetwork = Get-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Name $VirtualNetworkName `
        -ErrorAction Stop

    $overlappingSubnet = $virtualNetwork.Subnets | Where-Object {
        $_.AddressPrefix -eq $GatewaySubnetAddressPrefix -and $_.Name -ne "GatewaySubnet"
    }

    if ($overlappingSubnet) {
        throw "GatewaySubnetAddressPrefix overlaps with existing subnet '$($overlappingSubnet.Name)' using prefix '$GatewaySubnetAddressPrefix'."
    }

    $existingGatewaySubnet = $virtualNetwork.Subnets | Where-Object {
        $_.Name -eq "GatewaySubnet"
    }

    if ($existingGatewaySubnet) {
        Write-Host "GatewaySubnet already exists. Skipping creation."
        return $existingGatewaySubnet
    }

    Write-Host "GatewaySubnet not found. Creating GatewaySubnet with address prefix '$GatewaySubnetAddressPrefix'..."

    Add-AzVirtualNetworkSubnetConfig `
        -Name "GatewaySubnet" `
        -AddressPrefix $GatewaySubnetAddressPrefix `
        -VirtualNetwork $virtualNetwork | Out-Null

    $virtualNetwork | Set-AzVirtualNetwork | Out-Null

    Write-Host "GatewaySubnet created successfully."

    $updatedVirtualNetwork = Get-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Name $VirtualNetworkName `
        -ErrorAction Stop

}

    return ($updatedVirtualNetwork.Subnets | Where-Object {
        $_.Name -eq "GatewaySubnet"
    })
}

function Ensure-VpnGatewayPublicIp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$PublicIpName,

        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    Write-Host "Ensuring VPN Gateway Public IP '$PublicIpName' exists..."

    $existingPublicIp = Get-AzPublicIpAddress `
        -ResourceGroupName $ResourceGroupName `
        -Name $PublicIpName `
        -ErrorAction SilentlyContinue

    if ($existingPublicIp) {
        Write-Host "VPN Gateway Public IP already exists. Skipping creation."
        return $existingPublicIp
    }

    Write-Host "VPN Gateway Public IP not found. Creating Public IP..."

    $publicIp = New-AzPublicIpAddress `
        -ResourceGroupName $ResourceGroupName `
        -Name $PublicIpName `
        -Location $Location `
        -Sku Standard `
        -AllocationMethod Static

    Write-Host "VPN Gateway Public IP created successfully."

    return $publicIp
}

function Ensure-VirtualNetworkGateway {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$GatewayName,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $true)]
        [string]$VirtualNetworkName,

        [Parameter(Mandatory = $true)]
        [string]$PublicIpName
    )

    Write-Host "Ensuring Virtual Network Gateway '$GatewayName' exists..."

    $existingGateway = Get-AzVirtualNetworkGateway `
    -ResourceGroupName $ResourceGroupName `
    -Name $GatewayName `
    -ErrorAction SilentlyContinue

if ($existingGateway) {
    Write-Host "Virtual Network Gateway already exists. Skipping creation."
    return $existingGateway
}

Write-Host "Retrieving Virtual Network..."

$virtualNetwork = Get-AzVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Name $VirtualNetworkName `
    -ErrorAction Stop

Write-Host "Retrieving GatewaySubnet..."

$gatewaySubnet = $virtualNetwork.Subnets | Where-Object {
    $_.Name -eq "GatewaySubnet"
}

if (-not $gatewaySubnet) {
    throw "GatewaySubnet was not found in virtual network '$VirtualNetworkName'."
}

Write-Host "Retrieving VPN Gateway Public IP..."

$publicIp = Get-AzPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Name $PublicIpName `
    -ErrorAction Stop

    Write-Host "Creating gateway IP configuration..."

$gatewayIpConfig = New-AzVirtualNetworkGatewayIpConfig `
    -Name "gwipconfig" `
    -SubnetId $gatewaySubnet.Id `
    -PublicIpAddressId $publicIp.Id

    Write-Host "Creating Virtual Network Gateway..."

$virtualNetworkGateway = New-AzVirtualNetworkGateway `
    -ResourceGroupName $ResourceGroupName `
    -Name $GatewayName `
    -Location $Location `
    -IpConfigurations $gatewayIpConfig `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -GatewaySku VpnGw1

Write-Host "Virtual Network Gateway created successfully."

return $virtualNetworkGateway

}

function Ensure-PointToSiteConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$GatewayName,

        [Parameter(Mandatory = $true)]
        [string]$VpnClientAddressPool,

        [Parameter(Mandatory = $true)]
        [string]$RootCertificateName,

        [Parameter(Mandatory = $true)]
        [string]$RootCertificatePublicData
    )

    Write-Host "Ensuring Point-to-Site VPN configuration on gateway '$GatewayName'..."

    if ([string]::IsNullOrWhiteSpace($VpnClientAddressPool)) {
        throw "VpnClientAddressPool cannot be empty."
    }

    if ($VpnClientAddressPool -notmatch '^\d{1,3}(\.\d{1,3}){3}\/\d{1,2}$') {
        throw "VpnClientAddressPool must be a valid CIDR block, for example '172.16.201.0/24'."
    }

    if ([string]::IsNullOrWhiteSpace($RootCertificatePublicData)) {
        throw "RootCertificatePublicData cannot be empty."
    }

    $gateway = Get-AzVirtualNetworkGateway `
        -ResourceGroupName $ResourceGroupName `
        -Name $GatewayName `
        -ErrorAction Stop

    $existingAddressPool = $gateway.VpnClientConfiguration.VpnClientAddressPool.AddressPrefixes

    if ($existingAddressPool -contains $VpnClientAddressPool) {
        Write-Host "Point-to-Site address pool already configured."
    }

    $rootCertificate = New-AzVpnClientRootCertificate `
        -Name $RootCertificateName `
        -PublicCertData $RootCertificatePublicData

    $vpnClientAddressPool = New-Object Microsoft.Azure.Commands.Network.Models.PSAddressSpace
    $vpnClientAddressPool.AddressPrefixes = @($VpnClientAddressPool)

    Set-AzVirtualNetworkGateway `
        -VirtualNetworkGateway $gateway `
        -VpnClientAddressPool $vpnClientAddressPool `
        -VpnClientRootCertificates $rootCertificate `
        -VpnClientProtocol IkeV2,OpenVPN

    Write-Host "Point-to-Site VPN configuration applied successfully."

    return Get-AzVirtualNetworkGateway `
        -ResourceGroupName $ResourceGroupName `
        -Name $GatewayName `
        -ErrorAction Stop
}


Export-ModuleMember -Function `
    Ensure-GatewaySubnet, `
    Ensure-VpnGatewayPublicIp, `
    Ensure-VirtualNetworkGateway, `
    Ensure-PointToSiteConfiguration
