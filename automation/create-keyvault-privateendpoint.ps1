<#
.SYNOPSIS
  Creates a Private Endpoint + Private DNS for Azure Key Vault.

.DESCRIPTION
  This script ensures Private Link integration for the Key Vault:
    - Private Endpoint in subnet-data
    - Private DNS zone privatelink.vaultcore.azure.net
    - DNS Zone Group linking
    - Public network access disabled (optional)

  Idempotent: safe to run multiple times.
#>

[CmdletBinding()]
param(
    [string]$Environment        = "dev",
    [string]$Location           = "westeurope",
    [string]$ResourceGroupName  = "rg-dev-weu",
    [string]$VNetName           = "vnet-org-dev-weu",
    [string]$SubnetName         = "subnet-data"
)

$kvName = "kv-$Environment-weu-core"
$peName = "pep-$kvName"
$dnsZoneName = "privatelink.vaultcore.azure.net"

Write-Host "=== Creating Private Link for Key Vault '$kvName' ===" -ForegroundColor Cyan

# 1. Get KV
$kv = Get-AzKeyVault -VaultName $kvName -ErrorAction Stop

# 2. Get VNet + Subnet
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName
$subnet = $vnet.Subnets | Where-Object Name -eq $SubnetName

if (-not $subnet) { throw "Subnet '$SubnetName' not found." }

# 3. Ensure Private DNS Zone exists
$dns = Get-AzPrivateDnsZone -Name $dnsZoneName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $dns) {
    Write-Host "Creating Private DNS Zone: $dnsZoneName" -ForegroundColor Green
    $dns = New-AzPrivateDnsZone -Name $dnsZoneName -ResourceGroupName $ResourceGroupName
} else {
    Write-Host "Private DNS zone already exists." -ForegroundColor Yellow
}

# 4. Create PE connection object
$pls = New-AzPrivateLinkServiceConnection `
    -Name "pls-$kvName" `
    -PrivateLinkServiceId $kv.ResourceId `
    -GroupId "vault"

# 5. Ensure Private Endpoint exists
$existingPe = Get-AzPrivateEndpoint -Name $peName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if ($existingPe) {
    Write-Host "Private Endpoint already exists: $peName" -ForegroundColor Yellow
} else {
    Write-Host "Creating Private Endpoint: $peName" -ForegroundColor Green
    $pe = New-AzPrivateEndpoint `
        -Name $peName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Subnet $subnet `
        -PrivateLinkServiceConnection $pls
}

# 6. Create DNS Zone Group (connect PE -> DNS)
$zoneGroup = Get-AzPrivateDnsZoneGroup `
    -PrivateEndpointName $peName `
    -ResourceGroupName $ResourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $zoneGroup) {
    Write-Host "Creating DNS Zone Group..." -ForegroundColor Green
    New-AzPrivateDnsZoneGroup `
        -Name "zonegroup-$kvName" `
        -ResourceGroupName $ResourceGroupName `
        -PrivateEndpointName $peName `
        -PrivateDnsZoneConfig @(New-AzPrivateDnsZoneConfig -Name "cfg-kv" -PrivateDnsZoneId $dns.Id)
} else {
    Write-Host "DNS Zone Group already exists." -ForegroundColor Yellow
}

# 7. (Optional) Disable Public Access
Write-Host "Disabling public network access..." -ForegroundColor Green
Update-AzKeyVaultNetworkRuleSet `
    -VaultName $kvName `
    -ResourceGroupName $ResourceGroupName `
    -DefaultAction Deny `
    -Bypass AzureServices

Write-Host "`n=== Key Vault Private Endpoint setup complete ===" -ForegroundColor Green
