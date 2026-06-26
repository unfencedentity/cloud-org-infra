[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [Parameter(Mandatory = $true)]
    [string]$Location
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"

$storageAccountName = "st$core$Environment$Region".ToLower().Replace("-", "")

$vnetName = "vnet-core-$Environment-$Region"
$subnetName = "subnet-app"

$privateEndpointName = "pe-storage-$Environment-$Region"

$privateDnsZoneName = "privatelink.blob.core.windows.net"

Write-Host "Creating Private Endpoint..."
