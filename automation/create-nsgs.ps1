<#
.SYNOPSIS
  Creates and attaches Network Security Groups (NSGs) for core subnets.

.DESCRIPTION
  This script ensures that NSGs exist for the main subnets in vnet-org-dev-weu
  and associates them to:
    - subnet-core-services
    - subnet-apps
    - subnet-data

  It is idempotent: you can run it multiple times safely.

#>

[CmdletBinding()]
param(
    [string]$Environment = "dev",
    [string]$Location    = "westeurope",
    [string]$ResourceGroupName = "rg-dev-weu",
    [string]$VNetName    = "vnet-org-dev-weu"
)

Write-Host "=== NSG deployment for environment: $Environment ===" -ForegroundColor Cyan

# Build NSG names (simple pattern: nsg-<env>-<role>-weu)
$nsgCoreName = "nsg-$Environment-core-services-weu"
$nsgAppsName = "nsg-$Environment-apps-weu"
$nsgDataName = "nsg-$Environment-data-weu"

# Helper function: ensure NSG exists
function Ensure-NetworkSecurityGroup {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory)]
        [string]$Location
    )

    $existing = Get-AzNetworkSecurityGroup -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

    if ($null -ne $existing) {
        Write-Host "NSG '$Name' already exists in RG '$ResourceGroupName'." -ForegroundColor Yellow
        return $existing
    }

    Write-Host "Creating NSG '$Name' in RG '$ResourceGroupName'..." -ForegroundColor Green
    $nsg = New-AzNetworkSecurityGroup `
        -Name $Name `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location

    return $nsg
}

# 1. Ensure NSGs
$nsgCore = Ensure-NetworkSecurityGroup -Name $nsgCoreName -ResourceGroupName $ResourceGroupName -Location $Location
$nsgApps = Ensure-NetworkSecurityGroup -Name $nsgAppsName -ResourceGroupName $ResourceGroupName -Location $Location
$nsgData = Ensure-NetworkSecurityGroup -Name $nsgDataName -ResourceGroupName $ResourceGroupName -Location $Location

# 2. Get VNet and subnets
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

$subCore = $vnet.Subnets | Where-Object { $_.Name -eq "subnet-core-services" }
$subApps = $vnet.Subnets | Where-Object { $_.Name -eq "subnet-apps" }
$subData = $vnet.Subnets | Where-Object { $_.Name -eq "subnet-data" }

if (-not $subCore) { throw "Subnet 'subnet-core-services' not found in VNet '$VNetName'." }
if (-not $subApps) { throw "Subnet 'subnet-apps' not found in VNet '$VNetName'." }
if (-not $subData) { throw "Subnet 'subnet-data' not found in VNet '$VNetName'." }

# 3. Attach NSGs to subnets (idempotent)

if ($null -eq $subCore.NetworkSecurityGroup -or $subCore.NetworkSecurityGroup.Id -ne $nsgCore.Id) {
    Write-Host "Associating NSG '$($nsgCore.Name)' to subnet 'subnet-core-services'..." -ForegroundColor Green
    $subCore.NetworkSecurityGroup = $nsgCore
} else {
    Write-Host "Subnet 'subnet-core-services' already associated with NSG '$($nsgCore.Name)'." -ForegroundColor Yellow
}

if ($null -eq $subApps.NetworkSecurityGroup -or $subApps.NetworkSecurityGroup.Id -ne $nsgApps.Id) {
    Write-Host "Associating NSG '$($nsgApps.Name)' to subnet 'subnet-apps'..." -ForegroundColor Green
    $subApps.NetworkSecurityGroup = $nsgApps
} else {
    Write-Host "Subnet 'subnet-apps' already associated with NSG '$($nsgApps.Name)'." -ForegroundColor Yellow
}

if ($null -eq $subData.NetworkSecurityGroup -or $subData.NetworkSecurityGroup.Id -ne $nsgData.Id) {
    Write-Host "Associating NSG '$($nsgData.Name)' to subnet 'subnet-data'..." -ForegroundColor Green
    $subData.NetworkSecurityGroup = $nsgData
} else {
    Write-Host "Subnet 'subnet-data' already associated with NSG '$($nsgData.Name)'." -ForegroundColor Yellow
}

# 4. Save VNet changes
Set-AzVirtualNetwork -VirtualNetwork $vnet | Out-Null

Write-Host "`n=== NSG deployment completed successfully ===" -ForegroundColor Green
