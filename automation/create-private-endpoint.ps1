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

. "$PSScriptRoot\shared\DeploymentNaming.ps1"
. "$PSScriptRoot\shared\ObjectShape.ps1"

$names = Get-DeploymentNames -Environment $Environment -App $App -Region $Region

$resourceGroupName = $names.ResourceGroupName
$storageAccountName = $names.StorageAccountName
$vnetName = $names.CoreVNetName
$subnetName = "subnet-app"

$privateEndpointName = $names.PrivateEndpointName
$privateDnsZoneName = "privatelink.blob.core.windows.net"
$privateDnsZoneGroupName = "default"

Write-Host "Starting Private Endpoint deployment..."
Write-Host "Resource Group      : $resourceGroupName"
Write-Host "Storage Account     : $storageAccountName"
Write-Host "VNet                : $vnetName"
Write-Host "Subnet              : $subnetName"
Write-Host "Private Endpoint    : $privateEndpointName"
Write-Host "Private DNS Zone    : $privateDnsZoneName"
Write-Host "Location            : $Location"

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $resourceGroup) {
    throw "Resource group not found: $resourceGroupName"
}

$storageAccount = Get-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -ErrorAction SilentlyContinue

if (-not $storageAccount) {
    throw "Storage Account not found: $storageAccountName"
}

$vnet = Get-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Name $vnetName `
    -ErrorAction SilentlyContinue

if (-not $vnet) {
    throw "VNet not found: $vnetName"
}

$subnet = Get-AzVirtualNetworkSubnetConfig `
    -VirtualNetwork $vnet `
    -Name $subnetName `
    -ErrorAction SilentlyContinue

if (-not $subnet) {
    throw "Subnet not found: $subnetName"
}

$existingPrivateEndpoint = Get-AzPrivateEndpoint `
    -ResourceGroupName $resourceGroupName `
    -Name $privateEndpointName `
    -ErrorAction SilentlyContinue

$privateEndpoint = $existingPrivateEndpoint

if ($privateEndpoint) {
    Write-Host "Private Endpoint already exists: $privateEndpointName. Skipping creation."
}

$privateLinkServiceConnection = New-AzPrivateLinkServiceConnection `
    -Name "pls-storage-blob-$Environment-$Region" `
    -PrivateLinkServiceId $storageAccount.Id `
    -GroupId "blob"

if (-not $privateEndpoint -and $PSCmdlet.ShouldProcess($privateEndpointName, "Create Private Endpoint for Storage Blob")) {
    Write-Host "Creating Private Endpoint: $privateEndpointName"

    $privateEndpoint = New-AzPrivateEndpoint `
        -ResourceGroupName $resourceGroupName `
        -Name $privateEndpointName `
        -Location $Location `
        -Subnet $subnet `
        -PrivateLinkServiceConnection $privateLinkServiceConnection

    Write-Host "Private Endpoint created: $privateEndpointName"
}

$privateDnsZone = Get-AzPrivateDnsZone `
    -ResourceGroupName $resourceGroupName `
    -Name $privateDnsZoneName `
    -ErrorAction SilentlyContinue

if (-not $privateDnsZone) {
    if ($PSCmdlet.ShouldProcess($privateDnsZoneName, "Create Private DNS Zone")) {
        Write-Host "Creating Private DNS Zone: $privateDnsZoneName"

        $privateDnsZone = New-AzPrivateDnsZone `
            -ResourceGroupName $resourceGroupName `
            -Name $privateDnsZoneName

        Write-Host "Private DNS Zone created: $privateDnsZoneName"
    }
}
else {
    Write-Host "Private DNS Zone already exists: $privateDnsZoneName"
}

$existingVnetLink = Get-AzPrivateDnsVirtualNetworkLink `
    -ResourceGroupName $resourceGroupName `
    -ZoneName $privateDnsZoneName `
    -Name "link-$vnetName" `
    -ErrorAction SilentlyContinue

if (-not $existingVnetLink) {
    if ($PSCmdlet.ShouldProcess("link-$vnetName", "Create Private DNS VNet link")) {
        Write-Host "Creating Private DNS VNet link: link-$vnetName"

        New-AzPrivateDnsVirtualNetworkLink `
            -ResourceGroupName $resourceGroupName `
            -ZoneName $privateDnsZoneName `
            -Name "link-$vnetName" `
            -VirtualNetworkId $vnet.Id `
            -EnableRegistration:$false | Out-Null

        Write-Host "Private DNS VNet link created."
    }
}
else {
    Write-Host "Private DNS VNet link already exists: link-$vnetName"
}

$existingDnsZoneGroup = Get-AzPrivateDnsZoneGroup `
    -ResourceGroupName $resourceGroupName `
    -PrivateEndpointName $privateEndpointName `
    -Name $privateDnsZoneGroupName `
    -ErrorAction SilentlyContinue

if (-not $existingDnsZoneGroup) {
    $privateDnsZoneResourceId = Get-ObjectPropertyValue `
        -Object $privateDnsZone `
        -PropertyName "ResourceId"

    if ([string]::IsNullOrWhiteSpace($privateDnsZoneResourceId)) {
        $privateDnsZoneResourceId = Get-ObjectPropertyValue `
            -Object $privateDnsZone `
            -PropertyName "Id"
    }

    if ([string]::IsNullOrWhiteSpace($privateDnsZoneResourceId) -or -not $privateDnsZoneResourceId.StartsWith("/subscriptions/")) {
        throw "Private DNS Zone id could not be resolved to a valid ARM resource id for '$privateDnsZoneName'."
    }

    if ($PSCmdlet.ShouldProcess($privateEndpointName, "Create Private DNS Zone Group")) {
        Write-Host "Creating Private DNS Zone Group for Private Endpoint."

        New-AzPrivateDnsZoneGroup `
            -ResourceGroupName $resourceGroupName `
            -PrivateEndpointName $privateEndpointName `
            -Name $privateDnsZoneGroupName `
            -PrivateDnsZoneConfig @(
                New-AzPrivateDnsZoneConfig `
                    -Name "blob-config" `
                    -PrivateDnsZoneId $privateDnsZoneResourceId
            ) | Out-Null

        Write-Host "Private DNS Zone Group created."
    }
}
else {
    Write-Host "Private DNS Zone Group already exists."
}

Write-Host "Private Endpoint deployment completed successfully."
