param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Region
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\ObjectShape.ps1"

$resourceGroupName = "rg-$App-$Environment-$Region"
$vnetName = "vnet-$App-$Environment-$Region"
$vmName = "vm-$App-$Environment-$Region-01"

$dnsZoneName = "internal.cloudorg.local"
$vnetLinkName = "link-$vnetName"
$dnsRecordName = "vm-$App-$Environment-$Region"

Write-Host "Starting Private DNS configuration..."

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction Stop

$vnet = Get-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroupName `
    -ErrorAction Stop

$zone = Get-AzPrivateDnsZone `
    -Name $dnsZoneName `
    -ResourceGroupName $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $zone) {
    Write-Host "Creating Private DNS Zone: $dnsZoneName"

    $zone = New-AzPrivateDnsZone `
        -Name $dnsZoneName `
        -ResourceGroupName $resourceGroupName
}
else {
    Write-Host "Private DNS Zone already exists: $dnsZoneName"
}

$link = Get-AzPrivateDnsVirtualNetworkLink `
    -ZoneName $dnsZoneName `
    -ResourceGroupName $resourceGroupName `
    -Name $vnetLinkName `
    -ErrorAction SilentlyContinue

if (-not $link) {
    Write-Host "Creating VNet link: $vnetLinkName"

    New-AzPrivateDnsVirtualNetworkLink `
        -ZoneName $dnsZoneName `
        -ResourceGroupName $resourceGroupName `
        -Name $vnetLinkName `
        -VirtualNetworkId $vnet.Id `
        -EnableRegistration:$false | Out-Null
}
else {
    Write-Host "VNet link already exists: $vnetLinkName"
}

$vm = Get-AzVM `
    -Name $vmName `
    -ResourceGroupName $resourceGroupName `
    -ErrorAction Stop

$networkProfile = Get-ObjectPropertyValue -Object $vm -PropertyName "NetworkProfile"
$networkInterfaces = Get-ObjectPropertyValue -Object $networkProfile -PropertyName "NetworkInterfaces" -DefaultValue @()
$firstNetworkInterface = Get-FirstCollectionItem -Collection $networkInterfaces
$nicId = Get-ObjectPropertyValue -Object $firstNetworkInterface -PropertyName "Id"

if ([string]::IsNullOrWhiteSpace($nicId)) {
    throw "VM '$vmName' does not expose a network interface id in NetworkProfile.NetworkInterfaces."
}

$nicName = ($nicId -split "/")[-1]

$nic = Get-AzNetworkInterface `
    -Name $nicName `
    -ResourceGroupName $resourceGroupName `
    -ErrorAction Stop

$ipConfigurations = Get-ObjectPropertyValue -Object $nic -PropertyName "IpConfigurations" -DefaultValue @()
$firstIpConfiguration = Get-FirstCollectionItem -Collection $ipConfigurations
$privateIp = Get-ObjectPropertyValue -Object $firstIpConfiguration -PropertyName "PrivateIpAddress"

if ([string]::IsNullOrWhiteSpace($privateIp)) {
    throw "NIC '$nicName' does not expose a private IP address."
}

Write-Host "VM private IP detected: $privateIp"

$recordSet = Get-AzPrivateDnsRecordSet `
    -ZoneName $dnsZoneName `
    -ResourceGroupName $resourceGroupName `
    -Name $dnsRecordName `
    -RecordType A `
    -ErrorAction SilentlyContinue

if (-not $recordSet) {
    Write-Host "Creating A record: $dnsRecordName.$dnsZoneName -> $privateIp"

    New-AzPrivateDnsRecordSet `
        -ZoneName $dnsZoneName `
        -ResourceGroupName $resourceGroupName `
        -Name $dnsRecordName `
        -RecordType A `
        -Ttl 300 `
        -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $privateIp) | Out-Null
}
else {
    Write-Host "Updating A record: $dnsRecordName.$dnsZoneName -> $privateIp"

    $recordSet.Records.Clear()
    $recordSet.Records.Add((New-AzPrivateDnsRecordConfig -IPv4Address $privateIp))
    Set-AzPrivateDnsRecordSet -RecordSet $recordSet | Out-Null
}

$summary = [PSCustomObject]@{
    ResourceGroup   = $resourceGroupName
    PrivateDnsZone  = $dnsZoneName
    VNet            = $vnetName
    VNetLink        = $vnetLinkName
    VM              = $vmName
    RecordName      = "$dnsRecordName.$dnsZoneName"
    PrivateIp       = $privateIp
}

Write-Host "Private DNS configuration completed."
$summary | ConvertTo-Json -Depth 5
