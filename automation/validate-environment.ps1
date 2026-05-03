param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================="
Write-Host "AZURE ENVIRONMENT VALIDATION AUDIT"
Write-Host "============================================="
Write-Host ""

Write-Host ("Environment : {0}" -f $Environment)
Write-Host ("Application : {0}" -f $App)
Write-Host ("Region      : {0}" -f $Region)
Write-Host ("Location    : {0}" -f $Location)
Write-Host ""
$resourceGroupName = "rg-{0}-{1}-{2}" -f $App, $Environment, $Region

Write-Host "Checking Resource Group..."

$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if ($rg) {
    Write-Host ("[PASS] Resource Group found: {0}" -f $resourceGroupName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Resource Group missing: {0}" -f $resourceGroupName) -ForegroundColor Red
}
$vnetName = "vnet-{0}-{1}-{2}" -f $App, $Environment, $Region

Write-Host "Checking Virtual Network..."

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($vnet) {
    Write-Host ("[PASS] Virtual Network found: {0}" -f $vnetName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Virtual Network missing: {0}" -f $vnetName) -ForegroundColor Red
}
Write-Host "Checking required subnets..."

$requiredSubnets = @(
    "subnet-core-services",
    "subnet-apps"
)

if ($vnet) {
    foreach ($subnetName in $requiredSubnets) {
        $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

        if ($subnet) {
            Write-Host ("[PASS] Subnet found: {0}" -f $subnetName) -ForegroundColor Green
        }
        else {
            Write-Host ("[FAIL] Subnet missing: {0}" -f $subnetName) -ForegroundColor Red
        }
    }
}
else {
    foreach ($subnetName in $requiredSubnets) {
        Write-Host ("[SKIP] Cannot validate subnet because VNet is missing: {0}" -f $subnetName) -ForegroundColor Yellow
    }
}
Write-Host "Checking Network Security Groups..."

$requiredNsgs = @(
    "nsg-core-services",
    "nsg-apps"
)

foreach ($nsgName in $requiredNsgs) {
    $nsg = Get-AzNetworkSecurityGroup `
        -Name $nsgName `
        -ResourceGroupName $resourceGroupName `
        -ErrorAction SilentlyContinue

    if ($nsg) {
        Write-Host ("[PASS] NSG found: {0}" -f $nsgName) -ForegroundColor Green
    }
    else {
        Write-Host ("[FAIL] NSG missing: {0}" -f $nsgName) -ForegroundColor Red
    }
}

