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
