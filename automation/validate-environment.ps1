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

$validationResults = @()

function Add-ValidationResult {
    param (
        [string]$Name,
        [string]$Result,
        [string]$Message
    )

    $script:validationResults += [PSCustomObject]@{
        Name      = $Name
        Result    = $Result
        Message   = $Message
        Timestamp = (Get-Date).ToString("s")
    }
}

$resourceGroupName = "rg-{0}-{1}-{2}" -f $App, $Environment, $Region

Write-Host "Checking Resource Group..."

$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if ($rg) {
    Write-Host ("[PASS] Resource Group found: {0}" -f $resourceGroupName) -ForegroundColor Green
    Add-ValidationResult -Name "Resource Group" -Result "PASS" -Message ("Resource Group found: {0}" -f $resourceGroupName)
}
else {
    Write-Host ("[FAIL] Resource Group missing: {0}" -f $resourceGroupName) -ForegroundColor Red
    Add-ValidationResult -Name "Resource Group" -Result "FAIL" -Message ("Resource Group missing: {0}" -f $resourceGroupName)
}

$vnetName = "vnet-{0}-{1}-{2}" -f $App, $Environment, $Region

Write-Host "Checking Virtual Network..."

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue 

if ($vnet) {
    Write-Host ("[PASS] Virtual Network found: {0}" -f $vnetName) -ForegroundColor Green
    Add-ValidationResult -Name "Virtual Network" -Result "PASS" -Message ("Virtual Network found: {0}" -f $vnetName)
}
else {
    Write-Host ("[FAIL] Virtual Network missing: {0}" -f $vnetName) -ForegroundColor Red
    Add-ValidationResult -Name "Virtual Network" -Result "FAIL" -Message ("Virtual Network missing: {0}" -f $vnetName)
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

Write-Host "Checking Storage Account..."

$storagePattern = "st{0}{1}{2}" -f $App, $Environment, $Region
$storage = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue | Where-Object { $_.StorageAccountName -like "$storagePattern*" }

if ($storage) {
    Write-Host ("[PASS] Storage Account found: {0}" -f $storage.StorageAccountName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Storage Account missing.") -ForegroundColor Red
}

Write-Host "Checking Key Vault..."

$keyVaultName = "kv-{0}-{1}-{2}" -f $App, $Environment, $Region
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Write-Host ("[PASS] Key Vault found: {0}" -f $keyVaultName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Key Vault missing: {0}" -f $keyVaultName) -ForegroundColor Red
}

Write-Host "Checking Log Analytics Workspace..."

$lawName = "law-{0}-{1}-{2}" -f $App, $Environment, $Region
$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $lawName -ErrorAction SilentlyContinue

if ($law) {
    Write-Host ("[PASS] Log Analytics Workspace found: {0}" -f $lawName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Log Analytics Workspace missing: {0}" -f $lawName) -ForegroundColor Red
}

Write-Host "Checking Application Insights..."

$appInsightsName = "appi-{0}-{1}-{2}" -f $App, $Environment, $Region
$appInsights = Get-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $appInsightsName -ErrorAction SilentlyContinue

if ($appInsights) {
    Write-Host ("[PASS] Application Insights found: {0}" -f $appInsightsName) -ForegroundColor Green
}
else {
    Write-Host ("[FAIL] Application Insights missing: {0}" -f $appInsightsName) -ForegroundColor Red
}

Write-Host "Checking App Service..."

$appServiceName = "app-{0}-{1}-{2}" -f $App, $Environment, $Region
$appService = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $appServiceName -ErrorAction SilentlyContinue

if ($appService) {
    Write-Host ("[PASS] App Service found: {0}" -f $appServiceName) -ForegroundColor Green

    if ($appService.HttpsOnly -eq $true) {
        Write-Host "[PASS] App Service HTTPS-only is enabled." -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] App Service HTTPS-only is not enabled." -ForegroundColor Red
    }

    if ($appService.Identity -and $appService.Identity.Type) {
        Write-Host ("[PASS] Managed Identity configured: {0}" -f $appService.Identity.Type) -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] Managed Identity not configured on App Service." -ForegroundColor Yellow
    }
}
else {
    Write-Host ("[FAIL] App Service missing: {0}" -f $appServiceName) -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================="
Write-Host "VALIDATION AUDIT COMPLETED"
Write-Host "============================================="
Write-Host ""
Write-Host "Review PASS, WARN, and FAIL results above for environment compliance status."
