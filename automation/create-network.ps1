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
    }
)

$ErrorActionPreference = "Stop"

# Naming convention
$vnetName = "vnet-$App-$Environment-$Region"
$rgName   = "rg-$App-$Environment-$Region"

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

# Check if VNet exists
$existingVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

if ($existingVnet) {
    Write-Host "VNet '$vnetName' already exists. Skipping create."
    return $existingVnet
}

# Create subnet configurations
$subnetConfigs = @()
foreach ($key in $Subnets.Keys) {
    $subnetConfigs += New-AzVirtualNetworkSubnetConfig -Name $key -AddressPrefix $Subnets[$key]
}

if (-not $PSCmdlet.ShouldProcess("VNet $vnetName", "Create")) { return }

Write-Host "Creating VNet '$vnetName' in '$Location'..."

$newVnet = New-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $rgName `
    -Location $Location `
    -AddressPrefix $AddressPrefix `
    -Subnet $subnetConfigs `
    -Tag $tags

Write-Host "VNet '$vnetName' created successfully."

return $newVnet
