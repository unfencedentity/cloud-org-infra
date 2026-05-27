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

    $virtualNetwork = Get-AzVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Name $VirtualNetworkName `
        -ErrorAction Stop

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

    return ($updatedVirtualNetwork.Subnets | Where-Object {
        $_.Name -eq "GatewaySubnet"
    })
}

Export-ModuleMember -Function Ensure-GatewaySubnet
