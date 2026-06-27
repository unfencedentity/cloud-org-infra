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

$subscriptionId = $env:AZURE_SUBSCRIPTION_ID

$resourceGroupName = "rg-$App-$Environment-$Region"

$baseString = "$subscriptionId-$App-$Environment-$Region"

$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)

$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

$storageAccountName = "st$App$Environment$Region$hash"
$storageAccountName = $storageAccountName.ToLower().Replace("-", "")

$vnetName = "vnet-core-$Environment-$Region"
$subnetName = "subnet-app"

$privateEndpointName = "pe-storage-$Environment-$Region"
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

if ($existingPrivateEndpoint) {
    Write-Host "Private Endpoint already exists: $privateEndpointName. Skipping creation."
    return $existingPrivateEndpoint
}

$privateLinkServiceConnection = New-AzPrivateLinkServiceConnection `
    -Name "pls-storage-blob-$Environment-$Region" `
    -PrivateLinkServiceId $storageAccount.Id `
    -GroupId "blob"

if ($PSCmdlet.ShouldProcess($privateEndpointName, "Create Private Endpoint for Storage Blob")) {
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
    if ($PSCmdlet.ShouldProcess($privateEndpointName, "Create Private DNS Zone Group")) {
        Write-Host "Creating Private DNS Zone Group for Private Endpoint."

        New-AzPrivateDnsZoneGroup `
            -ResourceGroupName $resourceGroupName `
            -PrivateEndpointName $privateEndpointName `
            -Name $privateDnsZoneGroupName `
            -PrivateDnsZoneConfig @(
                New-AzPrivateDnsZoneConfig `
                    -Name "blob-config" `
                    -PrivateDnsZoneId $privateDnsZone.ResourceId
            ) | Out-Null

        Write-Host "Private DNS Zone Group created."
    }
}
else {
    Write-Host "Private DNS Zone Group already exists."
}

Write-Host "Private Endpoint deployment completed successfully."
