[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Optional: override default VNet name
    [Parameter(Mandatory = $false)][string]$VirtualNetworkName,

    # Optional: subnets to associate the NSG with (by subnet name)
    [Parameter(Mandatory = $false)][string[]]$SubnetsToAssociate = @("subnet-core", "subnet-app")
)

$ErrorActionPreference = "Stop"

# Naming conventions
$rgName  = "rg-$App-$Environment-$Region"
$vnetName = if ($VirtualNetworkName) { $VirtualNetworkName } else { "vnet-$App-$Environment-$Region" }
$nsgName = "nsg-$App-$Environment-$Region"

# Tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Validate Resource Group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# Try to get existing NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

if ($nsg) {
    Write-Host "Network Security Group '$nsgName' already exists in resource group '$rgName'."
}
else {
    if (-not $PSCmdlet.ShouldProcess("NSG $nsgName", "Create")) { return }

    Write-Host "Creating Network Security Group '$nsgName' in '$Location'..."

    # Example inbound rules for a web workload (HTTP/HTTPS from Internet)
    $ruleHttp = New-AzNetworkSecurityRuleConfig `
        -Name "allow-http-in" `
        -Description "Allow HTTP inbound from Internet" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 200 `
        -SourceAddressPrefix "*" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange 80

    $ruleHttps = New-AzNetworkSecurityRuleConfig `
        -Name "allow-https-in" `
        -Description "Allow HTTPS inbound from Internet" `
        -Access Allow `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 201 `
        -SourceAddressPrefix "*" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange 443

    $nsg = New-AzNetworkSecurityGroup `
        -Name $nsgName `
        -ResourceGroupName $rgName `
        -Location $Location `
        -SecurityRules $ruleHttp, $ruleHttps `
        -Tag $tags

    Write-Host "Network Security Group '$nsgName' created."
}

# Associate NSG with selected subnets in the VNet
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if (-not $vnet) {
    Write-Warning "Virtual network '$vnetName' not found in resource group '$rgName'. NSG will not be associated with any subnets."
    return $nsg
}

$updated = $false

foreach ($subnetName in $SubnetsToAssociate) {
    $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

    if (-not $subnet) {
        Write-Warning "Subnet '$subnetName' not found in VNet '$vnetName'. Skipping."
        continue
    }

    if ($subnet.NetworkSecurityGroup -and $subnet.NetworkSecurityGroup.Id -eq $nsg.Id) {
        Write-Host "Subnet '$subnetName' is already associated with NSG '$nsgName'."
        continue
    }

    Write-Host "Associating subnet '$subnetName' with NSG '$nsgName'..."
    $subnet.NetworkSecurityGroup = $nsg
    $updated = $true
}

if ($updated) {
    if (-not $PSCmdlet.ShouldProcess("VNet $vnetName", "Update with NSG associations")) { return $nsg }

    $null = Set-AzVirtualNetwork -VirtualNetwork $vnet
    Write-Host "VNet '$vnetName' updated with NSG associations."
}
else {
    Write-Host "No subnet associations were changed."
}

return $nsg
