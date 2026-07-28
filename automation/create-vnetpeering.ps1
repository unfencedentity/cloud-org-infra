[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $false)][string]$CoreVNetName,
    [Parameter(Mandatory = $false)][string]$HubVNetName,
    [Parameter(Mandatory = $false)][string]$CoreToHubPeeringName = "peer-core-to-hub",
    [Parameter(Mandatory = $false)][string]$HubToCorePeeringName = "peer-hub-to-core"
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"
$coreVnetNameResolved = if ([string]::IsNullOrWhiteSpace($CoreVNetName)) {
    "vnet-$App-$Environment-$Region"
}
else {
    $CoreVNetName
}

$hubVnetNameResolved = if ([string]::IsNullOrWhiteSpace($HubVNetName)) {
    "vnet-hub-$Environment-$Region"
}
else {
    $HubVNetName
}

function ConvertTo-UInt32Ip {
    param(
        [Parameter(Mandatory = $true)][string]$IpAddress
    )

    $bytes = [System.Net.IPAddress]::Parse($IpAddress).GetAddressBytes()
    [Array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Get-IPv4CidrRange {
    param(
        [Parameter(Mandatory = $true)][string]$Cidr
    )

    if ($Cidr -notmatch '^(?<ip>(\d{1,3}\.){3}\d{1,3})\/(?<prefix>\d{1,2})$') {
        throw "Invalid CIDR format: '$Cidr'."
    }

    $prefixLength = [int]$Matches.prefix

    if ($prefixLength -lt 0 -or $prefixLength -gt 32) {
        throw "Invalid CIDR prefix length in '$Cidr'."
    }

    $ipValue = ConvertTo-UInt32Ip -IpAddress $Matches.ip
    $mask = if ($prefixLength -eq 0) { [uint32]0 } else { [uint32]::MaxValue -shl (32 - $prefixLength) }

    $network = $ipValue -band $mask
    $broadcast = $network + ([uint32]::MaxValue -bxor $mask)

    return [PSCustomObject]@{
        Cidr      = $Cidr
        Start     = $network
        End       = $broadcast
        PrefixLen = $prefixLength
    }
}

function Test-CidrOverlap {
    param(
        [Parameter(Mandatory = $true)][string[]]$Left,
        [Parameter(Mandatory = $true)][string[]]$Right
    )

    foreach ($leftCidr in $Left) {
        $leftRange = Get-IPv4CidrRange -Cidr $leftCidr

        foreach ($rightCidr in $Right) {
            $rightRange = Get-IPv4CidrRange -Cidr $rightCidr

            if ($leftRange.Start -le $rightRange.End -and $rightRange.Start -le $leftRange.End) {
                return [PSCustomObject]@{
                    Overlap   = $true
                    LeftCidr  = $leftCidr
                    RightCidr = $rightCidr
                }
            }
        }
    }

    return [PSCustomObject]@{ Overlap = $false }
}

function Test-PeeringConfigurationMatch {
    param(
        [Parameter(Mandatory = $true)]$Peering,
        [Parameter(Mandatory = $true)][string]$RemoteVirtualNetworkId
    )

    if ($Peering.RemoteVirtualNetwork.Id -ne $RemoteVirtualNetworkId) { return $false }
    if ($Peering.AllowVirtualNetworkAccess -ne $true) { return $false }
    if ($Peering.AllowForwardedTraffic -ne $false) { return $false }
    if ($Peering.AllowGatewayTransit -ne $false) { return $false }
    if ($Peering.UseRemoteGateways -ne $false) { return $false }

    return $true
}

function Ensure-VNetPeering {
    param(
        [Parameter(Mandatory = $true)][string]$PeeringName,
        [Parameter(Mandatory = $true)][string]$LocalVNetName,
        [Parameter(Mandatory = $true)][string]$RemoteVNetName,
        [Parameter(Mandatory = $true)][string]$RemoteVNetId
    )

    $existingPeering = Get-AzVirtualNetworkPeering `
        -Name $PeeringName `
        -VirtualNetworkName $LocalVNetName `
        -ResourceGroupName $resourceGroupName `
        -ErrorAction SilentlyContinue

    if (-not $existingPeering) {
        if (-not $PSCmdlet.ShouldProcess("VNet peering '$PeeringName'", "Create from '$LocalVNetName' to '$RemoteVNetName'")) {
            return $null
        }

        Write-Host "Creating VNet peering '$PeeringName' from '$LocalVNetName' to '$RemoteVNetName'..."

        # Keep forwarding/transit/remote-gateway disabled until a routing stack exists (Azure Firewall/NVA/VPN Gateway/Route Server).
        $localVNet = Get-AzVirtualNetwork `
    -Name $LocalVNetName `
    -ResourceGroupName $resourceGroupName

        return Add-AzVirtualNetworkPeering `
    -Name $PeeringName `
    -VirtualNetwork $localVNet `
    -RemoteVirtualNetworkId $RemoteVNetId
    }

    if (Test-PeeringConfigurationMatch -Peering $existingPeering -RemoteVirtualNetworkId $RemoteVNetId) {
        Write-Host "VNet peering '$PeeringName' already exists with the desired configuration."
        return $existingPeering
    }

    if ($existingPeering.RemoteVirtualNetwork.Id -ne $RemoteVNetId) {
        throw "VNet peering '$PeeringName' on '$LocalVNetName' points to a different remote VNet. Remove peering '$PeeringName' and recreate it for remote VNet '$RemoteVNetName'. Existing remote VNet Id: '$($existingPeering.RemoteVirtualNetwork.Id)'. Desired remote VNet Id: '$RemoteVNetId'."
    }

    if (-not $PSCmdlet.ShouldProcess("VNet peering '$PeeringName'", "Update configuration")) {
        return $existingPeering
    }

    Write-Host "Updating VNet peering '$PeeringName' to match desired configuration..."

    # Keep forwarding/transit/remote-gateway disabled until a routing stack exists (Azure Firewall/NVA/VPN Gateway/Route Server).
    $existingPeering.AllowVirtualNetworkAccess = $true
    $existingPeering.AllowForwardedTraffic = $false
    $existingPeering.AllowGatewayTransit = $false
    $existingPeering.UseRemoteGateways = $false

    return Set-AzVirtualNetworkPeering -VirtualNetworkPeering $existingPeering
}

$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    throw "Resource group '$resourceGroupName' does not exist. Run create-rg.ps1 or deploy-environment.ps1 first."
}

$coreVnet = Get-AzVirtualNetwork -Name $coreVnetNameResolved -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $coreVnet) {
    throw "Core VNet '$coreVnetNameResolved' not found in resource group '$resourceGroupName'. Run create-network.ps1 first."
}

$hubVnet = Get-AzVirtualNetwork -Name $hubVnetNameResolved -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $hubVnet) {
    throw "Hub VNet '$hubVnetNameResolved' not found in resource group '$resourceGroupName'. Run create-network.ps1 first."
}

$corePrefixes = @($coreVnet.AddressSpace.AddressPrefixes)
$hubPrefixes = @($hubVnet.AddressSpace.AddressPrefixes)
$overlapResult = Test-CidrOverlap -Left $corePrefixes -Right $hubPrefixes

if ($overlapResult.Overlap) {
    throw "VNet address spaces overlap. Resolve CIDR conflict before peering. Conflicting prefixes: '$($overlapResult.LeftCidr)' and '$($overlapResult.RightCidr)'."
}

$coreToHubPeering = Ensure-VNetPeering `
    -PeeringName $CoreToHubPeeringName `
    -LocalVNetName $coreVnet.Name `
    -RemoteVNetName $hubVnet.Name `
    -RemoteVNetId $hubVnet.Id

$hubToCorePeering = Ensure-VNetPeering `
    -PeeringName $HubToCorePeeringName `
    -LocalVNetName $hubVnet.Name `
    -RemoteVNetName $coreVnet.Name `
    -RemoteVNetId $coreVnet.Id

return [PSCustomObject]@{
    CoreToHubPeering = $coreToHubPeering
    HubToCorePeering = $hubToCorePeering
}
