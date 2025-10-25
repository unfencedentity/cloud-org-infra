# create-network.ps1
# Creează vNet + 3 subnets + NSG conform naming & tagging policies
# Ex: .\create-network.ps1 -Env dev -Region weu -AppName core -Location westeurope -AddressPrefix 10.10.0.0/16

param(
    [ValidateSet("dev","test","prod")]
    [string]$Env = "dev",
    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region = "weu",
    [string]$AppName = "core",
    [string]$Location = "westeurope",
    [string]$AddressPrefix = "10.10.0.0/16",
    [string]$SubnetWeb = "10.10.1.0/24",
    [string]$SubnetApp = "10.10.2.0/24",
    [string]$SubnetData = "10.10.3.0/24",
    [string]$RgName
)

# ---------- Naming ----------
if (-not $RgName) { $RgName = "$Env-rg-$Region-$AppName" }
$vnetName = "$Env-vnet-$Region-$AppName"
$nsgWeb   = "$Env-nsg-$Region-web"
$nsgApp   = "$Env-nsg-$Region-app"
$nsgData  = "$Env-nsg-$Region-data"

# ---------- Tags ----------
$tags = @{
    env        = $Env
    owner      = "lucian.s@cloudorg.local"
    costCenter = "CC1001"
    app        = "cloud-org-$AppName"
    dataClass  = "internal"
}

# ---------- RG ----------
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location -Tag $tags | Out-Null
    Write-Host "✅ Created RG $RgName"
}

# ---------- NSG rules (basic: allow HTTP/HTTPS on web, deny inbound by default otherwise) ----------
$ruleHttp  = New-AzNetworkSecurityRuleConfig -Name "allow-http"  -Description "Allow HTTP"  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 80
$ruleHttps = New-AzNetworkSecurityRuleConfig -Name "allow-https" -Description "Allow HTTPS" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 443

$webNsg  = New-AzNetworkSecurityGroup -Name $nsgWeb  -ResourceGroupName $RgName -Location $Location -SecurityRules @($ruleHttp, $ruleHttps) -Tag $tags
$appNsg  = New-AzNetworkSecurityGroup -Name $nsgApp  -ResourceGroupName $RgName -Location $Location -Tag $tags
$dataNsg = New-AzNetworkSecurityGroup -Name $nsgData -ResourceGroupName $RgName -Location $Location -Tag $tags

# ---------- Subnet configs ----------
$subWeb  = New-AzVirtualNetworkSubnetConfig -Name "snet-web"  -AddressPrefix $SubnetWeb  -NetworkSecurityGroup $webNsg
$subApp  = New-AzVirtualNetworkSubnetConfig -Name "snet-app"  -AddressPrefix $SubnetApp  -NetworkSecurityGroup $appNsg
$subData = New-AzVirtualNetworkSubnetConfig -Name "snet-data" -AddressPrefix $SubnetData -NetworkSecurityGroup $dataNsg

# ---------- vNet ----------
$vnet = New-AzVirtualNetwork `
  -Name $vnetName `
  -ResourceGroupName $RgName `
  -Location $Location `
  -AddressPrefix $AddressPrefix `
  -Subnet $subWeb, $subApp, $subData `
  -Tag $tags

Write-Host "✅ vNet '$($vnet.Name)' created with subnets: snet-web, snet-app, snet-data"
