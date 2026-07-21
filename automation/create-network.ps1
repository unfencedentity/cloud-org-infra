[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $false)][string]$AddressPrefix = "10.10.0.0/16",
    [Parameter(Mandatory = $false)][hashtable]$Subnets = @{
        "subnet-core" = "10.10.1.0/24"
        "subnet-app"  = "10.10.2.0/24"
        "subnet-data" = "10.10.3.0/24"
    },
    [Parameter(Mandatory = $false)][string]$HubVNetName,
    [Parameter(Mandatory = $false)][string]$HubAddressPrefix = "10.20.0.0/16",
    [Parameter(Mandatory = $false)][string]$HubSubnetName = "subnet-hub-services",
    [Parameter(Mandatory = $false)][string]$HubSubnetPrefix = "10.20.0.0/24"
)

$ErrorActionPreference = "Stop"

# Naming convention
$coreVNetName = "vnet-$App-$Environment-$Region"
$hubVNetName = if ([string]::IsNullOrWhiteSpace($HubVNetName)) {
    "vnet-hub-$Environment-$Region"
}
else {
    $HubVNetName
}

$rgName = "rg-$App-$Environment-$Region"

# Tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Validate RG exists
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

function Test-AddressPrefixMatch {
    param(
        [Parameter(Mandatory = $true)][string[]]$Actual,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    $normalizedActual = @($Actual | ForEach-Object { $_.Trim().ToLowerInvariant() })
    $normalizedExpected = $Expected.Trim().ToLowerInvariant()

    return $normalizedActual -contains $normalizedExpected
}

function Ensure-VNet {
    param(
        [Parameter(Mandatory = $true)][string]$VNetName,
        [Parameter(Mandatory = $true)][string]$VNetAddressPrefix,
        [Parameter(Mandatory = $true)][hashtable]$DesiredSubnets
    )

    $existingVnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

    if (-not $existingVnet) {
        $subnetConfigs = @()
        foreach ($key in $DesiredSubnets.Keys) {
            $subnetConfigs += New-AzVirtualNetworkSubnetConfig -Name $key -AddressPrefix $DesiredSubnets[$key]
        }

        if (-not $PSCmdlet.ShouldProcess("VNet $VNetName", "Create")) {
            return $null
        }

        Write-Host "Creating VNet '$VNetName' in '$Location'..."

        $newVnet = New-AzVirtualNetwork `
            -Name $VNetName `
            -ResourceGroupName $rgName `
            -Location $Location `
            -AddressPrefix $VNetAddressPrefix `
            -Subnet $subnetConfigs `
            -Tag $tags

        Write-Host "VNet '$VNetName' created successfully."
        return $newVnet
    }

    if (-not (Test-AddressPrefixMatch -Actual $existingVnet.AddressSpace.AddressPrefixes -Expected $VNetAddressPrefix)) {
        $actualPrefixes = ($existingVnet.AddressSpace.AddressPrefixes -join ", ")
        throw "VNet '$VNetName' already exists with conflicting address space(s): [$actualPrefixes]. Expected to include '$VNetAddressPrefix'."
    }

    Write-Host "VNet '$VNetName' already exists and address space is valid."

    $vnetUpdated = $false
    foreach ($subnetName in $DesiredSubnets.Keys) {
        $expectedPrefix = $DesiredSubnets[$subnetName]
        $existingSubnet = $existingVnet.Subnets | Where-Object { $_.Name -eq $subnetName }

        if ($existingSubnet) {
            $actualSubnetPrefixes = @($existingSubnet.AddressPrefix)
            if ($existingSubnet.AddressPrefixes) {
                $actualSubnetPrefixes = @($existingSubnet.AddressPrefixes)
            }

            if (-not (Test-AddressPrefixMatch -Actual $actualSubnetPrefixes -Expected $expectedPrefix)) {
                $actual = ($actualSubnetPrefixes -join ", ")
                throw "Subnet '$subnetName' on VNet '$VNetName' has conflicting prefix(es): [$actual]. Expected '$expectedPrefix'."
            }

            Write-Host "Subnet '$subnetName' already exists on VNet '$VNetName' and prefix is valid."
            continue
        }

        if (-not $PSCmdlet.ShouldProcess("Subnet $subnetName on VNet $VNetName", "Create")) {
            continue
        }

        Write-Host "Creating subnet '$subnetName' on VNet '$VNetName'..."

        $null = Add-AzVirtualNetworkSubnetConfig `
            -Name $subnetName `
            -AddressPrefix $expectedPrefix `
            -VirtualNetwork $existingVnet

        $vnetUpdated = $true
    }

    if ($vnetUpdated) {
        if (-not $PSCmdlet.ShouldProcess("VNet $VNetName", "Update with subnet changes")) {
            return $existingVnet
        }

        $existingVnet = Set-AzVirtualNetwork -VirtualNetwork $existingVnet
        Write-Host "VNet '$VNetName' updated with missing subnet(s)."
    }

    return $existingVnet
}

$coreVnet = Ensure-VNet `
    -VNetName $coreVNetName `
    -VNetAddressPrefix $AddressPrefix `
    -DesiredSubnets $Subnets

$hubSubnets = @{ $HubSubnetName = $HubSubnetPrefix }
$hubVnet = Ensure-VNet `
    -VNetName $hubVNetName `
    -VNetAddressPrefix $HubAddressPrefix `
    -DesiredSubnets $hubSubnets

return [PSCustomObject]@{
    CoreVirtualNetwork = $coreVnet
    HubVirtualNetwork  = $hubVnet
}
