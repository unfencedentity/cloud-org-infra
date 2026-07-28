param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region,
    [string]$Location,

    [string]$ResourceGroupName,
    [string]$VNetName,
    [string]$HubVNetName,
    [string]$HubSubnetName = "subnet-hub-services",
    [string]$HubSubnetPrefix = "10.20.0.0/24",
    [string]$CoreToHubPeeringName = "peer-core-to-hub",
    [string]$HubToCorePeeringName = "peer-hub-to-core",
    [string[]]$RequiredSubnetNames = @("subnet-core-services", "subnet-apps"),
    [string[]]$RequiredNsgNames = @("nsg-core-services", "nsg-apps")
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\DeploymentDefaults.ps1"

$deploymentContext = Resolve-DeploymentRegionLocation -Region $Region -Location $Location
$Region = $deploymentContext.Region
$Location = $deploymentContext.Location

if ([string]::IsNullOrWhiteSpace($ResourceGroupName)) {
    $ResourceGroupName = "rg-{0}-{1}-{2}" -f $App, $Environment, $Region
}

if ([string]::IsNullOrWhiteSpace($VNetName)) {
    $VNetName = "vnet-{0}-{1}-{2}" -f $App, $Environment, $Region
}

if ([string]::IsNullOrWhiteSpace($HubVNetName)) {
    $HubVNetName = "vnet-hub-{0}-{1}" -f $Environment, $Region
}

Write-Host ""
Write-Host "============================================="
Write-Host "AZURE ENVIRONMENT VALIDATION AUDIT"
Write-Host "============================================="
Write-Host ""

Write-Host ("Environment : {0}" -f $Environment)
Write-Host ("Application : {0}" -f $App)
Write-Host ("Region      : {0}" -f $Region)
Write-Host ("Location    : {0}" -f $Location)
Write-Host ("Resource RG : {0}" -f $ResourceGroupName)
Write-Host ("VNet        : {0}" -f $VNetName)
Write-Host ("Hub VNet    : {0}" -f $HubVNetName)
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

Write-Host "Checking Resource Group..."

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

if ($rg) {
    Write-Host ("[PASS] Resource Group found: {0}" -f $ResourceGroupName) -ForegroundColor Green
    Add-ValidationResult -Name "Resource Group" -Result "PASS" -Message ("Resource Group found: {0}" -f $ResourceGroupName)
}
else {
    Write-Host ("[FAIL] Resource Group missing: {0}" -f $ResourceGroupName) -ForegroundColor Red
    Add-ValidationResult -Name "Resource Group" -Result "FAIL" -Message ("Resource Group missing: {0}" -f $ResourceGroupName)
}

Write-Host "Checking Virtual Network..."

$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if ($vnet) {
    Write-Host ("[PASS] Virtual Network found: {0}" -f $VNetName) -ForegroundColor Green
    Add-ValidationResult -Name "Virtual Network" -Result "PASS" -Message ("Virtual Network found: {0}" -f $VNetName)
}
else {
    Write-Host ("[FAIL] Virtual Network missing: {0}" -f $VNetName) -ForegroundColor Red
    Add-ValidationResult -Name "Virtual Network" -Result "FAIL" -Message ("Virtual Network missing: {0}" -f $VNetName)
}

Write-Host "Checking required subnets..."

if ($vnet) {
    foreach ($subnetName in $RequiredSubnetNames) {
        $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

        if ($subnet) {
            Write-Host ("[PASS] Subnet found: {0}" -f $subnetName) -ForegroundColor Green
            Add-ValidationResult -Name "Subnet" -Result "PASS" -Message ("Subnet found: {0}" -f $subnetName)
        }
        else {
            Write-Host ("[FAIL] Subnet missing: {0}" -f $subnetName) -ForegroundColor Red
            Add-ValidationResult -Name "Subnet" -Result "FAIL" -Message ("Subnet missing: {0}" -f $subnetName)
        }
    }
}
else {
    foreach ($subnetName in $RequiredSubnetNames) {
        Write-Host ("[SKIP] Cannot validate subnet because VNet is missing: {0}" -f $subnetName) -ForegroundColor Yellow
        Add-ValidationResult -Name "Subnet" -Result "SKIP" -Message ("Cannot validate subnet because VNet is missing: {0}" -f $subnetName)
    }
}

Write-Host "Checking Hub Virtual Network..."

$hubVnet = Get-AzVirtualNetwork -Name $HubVNetName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if ($hubVnet) {
    Write-Host ("[PASS] Hub Virtual Network found: {0}" -f $HubVNetName) -ForegroundColor Green
    Add-ValidationResult -Name "Hub Virtual Network" -Result "PASS" -Message ("Hub Virtual Network found: {0}" -f $HubVNetName)
}
else {
    Write-Host ("[FAIL] Hub Virtual Network missing: {0}" -f $HubVNetName) -ForegroundColor Red
    Add-ValidationResult -Name "Hub Virtual Network" -Result "FAIL" -Message ("Hub Virtual Network missing: {0}" -f $HubVNetName)
}

Write-Host "Checking Hub subnet..."

if ($hubVnet) {
    $hubSubnet = $hubVnet.Subnets | Where-Object { $_.Name -eq $HubSubnetName }

    if ($hubSubnet) {
        $actualHubSubnetPrefixes = @()
        $hubSubnetPropertyNames = @($hubSubnet.PSObject.Properties.Name)

        if ($hubSubnetPropertyNames -contains "AddressPrefixes") {
            $actualHubSubnetPrefixes = @($hubSubnet.AddressPrefixes)
        }
        elseif ($hubSubnetPropertyNames -contains "AddressPrefix") {
            $actualHubSubnetPrefixes = @($hubSubnet.AddressPrefix)
        }

        if ($actualHubSubnetPrefixes -contains $HubSubnetPrefix) {
            Write-Host ("[PASS] Hub subnet found with expected prefix: {0} ({1})" -f $HubSubnetName, $HubSubnetPrefix) -ForegroundColor Green
            Add-ValidationResult -Name "Hub Subnet" -Result "PASS" -Message ("Hub subnet found with expected prefix: {0} ({1})" -f $HubSubnetName, $HubSubnetPrefix)
        }
        else {
            $actualHubPrefixesText = $actualHubSubnetPrefixes -join ", "
            Write-Host ("[FAIL] Hub subnet prefix mismatch for {0}. Expected: {1}. Actual: {2}" -f $HubSubnetName, $HubSubnetPrefix, $actualHubPrefixesText) -ForegroundColor Red
            Add-ValidationResult -Name "Hub Subnet" -Result "FAIL" -Message ("Hub subnet prefix mismatch for {0}. Expected: {1}. Actual: {2}" -f $HubSubnetName, $HubSubnetPrefix, $actualHubPrefixesText)
        }
    }
    else {
        Write-Host ("[FAIL] Hub subnet missing: {0}" -f $HubSubnetName) -ForegroundColor Red
        Add-ValidationResult -Name "Hub Subnet" -Result "FAIL" -Message ("Hub subnet missing: {0}" -f $HubSubnetName)
    }
}
else {
    Write-Host ("[SKIP] Cannot validate hub subnet because Hub VNet is missing: {0}" -f $HubSubnetName) -ForegroundColor Yellow
    Add-ValidationResult -Name "Hub Subnet" -Result "SKIP" -Message ("Cannot validate hub subnet because Hub VNet is missing: {0}" -f $HubSubnetName)
}

Write-Host "Checking VNet peerings..."

$expectedAllowVnetAccess = $true
$expectedAllowForwarded = $false
$expectedAllowGatewayTransit = $false
$expectedUseRemoteGateways = $false

if ($vnet -and $hubVnet) {
    $coreToHubPeering = Get-AzVirtualNetworkPeering `
        -Name $CoreToHubPeeringName `
        -VirtualNetworkName $VNetName `
        -ResourceGroupName $ResourceGroupName `
        -ErrorAction SilentlyContinue

    if ($coreToHubPeering) {
        if ($coreToHubPeering.PeeringState -eq "Connected") {
            Write-Host ("[PASS] VNet peering connected: {0}" -f $CoreToHubPeeringName) -ForegroundColor Green
            Add-ValidationResult -Name "VNet Peering CoreToHub State" -Result "PASS" -Message ("Peering connected: {0}" -f $CoreToHubPeeringName)
        }
        else {
            Write-Host ("[FAIL] VNet peering state is not Connected for {0}. Current state: {1}" -f $CoreToHubPeeringName, $coreToHubPeering.PeeringState) -ForegroundColor Red
            Add-ValidationResult -Name "VNet Peering CoreToHub State" -Result "FAIL" -Message ("Peering state is not Connected for {0}. Current state: {1}" -f $CoreToHubPeeringName, $coreToHubPeering.PeeringState)
        }

        $coreToHubSettingsMatch =
            ($coreToHubPeering.AllowVirtualNetworkAccess -eq $expectedAllowVnetAccess) -and
            ($coreToHubPeering.AllowForwardedTraffic -eq $expectedAllowForwarded) -and
            ($coreToHubPeering.AllowGatewayTransit -eq $expectedAllowGatewayTransit) -and
            ($coreToHubPeering.UseRemoteGateways -eq $expectedUseRemoteGateways)

        if ($coreToHubSettingsMatch) {
            Write-Host ("[PASS] VNet peering settings match for {0}" -f $CoreToHubPeeringName) -ForegroundColor Green
            Add-ValidationResult -Name "VNet Peering CoreToHub Settings" -Result "PASS" -Message ("Peering settings match for {0}" -f $CoreToHubPeeringName)
        }
        else {
            Write-Host ("[FAIL] VNet peering settings mismatch for {0}" -f $CoreToHubPeeringName) -ForegroundColor Red
            Add-ValidationResult -Name "VNet Peering CoreToHub Settings" -Result "FAIL" -Message ("Peering settings mismatch for {0}" -f $CoreToHubPeeringName)
        }
    }
    else {
        Write-Host ("[FAIL] VNet peering missing: {0}" -f $CoreToHubPeeringName) -ForegroundColor Red
        Add-ValidationResult -Name "VNet Peering CoreToHub" -Result "FAIL" -Message ("VNet peering missing: {0}" -f $CoreToHubPeeringName)
    }

    $hubToCorePeering = Get-AzVirtualNetworkPeering `
        -Name $HubToCorePeeringName `
        -VirtualNetworkName $HubVNetName `
        -ResourceGroupName $ResourceGroupName `
        -ErrorAction SilentlyContinue

    if ($hubToCorePeering) {
        if ($hubToCorePeering.PeeringState -eq "Connected") {
            Write-Host ("[PASS] VNet peering connected: {0}" -f $HubToCorePeeringName) -ForegroundColor Green
            Add-ValidationResult -Name "VNet Peering HubToCore State" -Result "PASS" -Message ("Peering connected: {0}" -f $HubToCorePeeringName)
        }
        else {
            Write-Host ("[FAIL] VNet peering state is not Connected for {0}. Current state: {1}" -f $HubToCorePeeringName, $hubToCorePeering.PeeringState) -ForegroundColor Red
            Add-ValidationResult -Name "VNet Peering HubToCore State" -Result "FAIL" -Message ("Peering state is not Connected for {0}. Current state: {1}" -f $HubToCorePeeringName, $hubToCorePeering.PeeringState)
        }

        $hubToCoreSettingsMatch =
            ($hubToCorePeering.AllowVirtualNetworkAccess -eq $expectedAllowVnetAccess) -and
            ($hubToCorePeering.AllowForwardedTraffic -eq $expectedAllowForwarded) -and
            ($hubToCorePeering.AllowGatewayTransit -eq $expectedAllowGatewayTransit) -and
            ($hubToCorePeering.UseRemoteGateways -eq $expectedUseRemoteGateways)

        if ($hubToCoreSettingsMatch) {
            Write-Host ("[PASS] VNet peering settings match for {0}" -f $HubToCorePeeringName) -ForegroundColor Green
            Add-ValidationResult -Name "VNet Peering HubToCore Settings" -Result "PASS" -Message ("Peering settings match for {0}" -f $HubToCorePeeringName)
        }
        else {
            Write-Host ("[FAIL] VNet peering settings mismatch for {0}" -f $HubToCorePeeringName) -ForegroundColor Red
            Add-ValidationResult -Name "VNet Peering HubToCore Settings" -Result "FAIL" -Message ("Peering settings mismatch for {0}" -f $HubToCorePeeringName)
        }
    }
    else {
        Write-Host ("[FAIL] VNet peering missing: {0}" -f $HubToCorePeeringName) -ForegroundColor Red
        Add-ValidationResult -Name "VNet Peering HubToCore" -Result "FAIL" -Message ("VNet peering missing: {0}" -f $HubToCorePeeringName)
    }
}
else {
    Write-Host "[SKIP] Cannot validate VNet peerings because one or both VNets are missing." -ForegroundColor Yellow
    Add-ValidationResult -Name "VNet Peering" -Result "SKIP" -Message "Cannot validate VNet peerings because one or both VNets are missing."
}

Write-Host "Checking Network Security Groups..."

foreach ($nsgName in $RequiredNsgNames) {
    $nsg = Get-AzNetworkSecurityGroup `
        -Name $nsgName `
        -ResourceGroupName $ResourceGroupName `
        -ErrorAction SilentlyContinue

    if ($nsg) {
        Write-Host ("[PASS] NSG found: {0}" -f $nsgName) -ForegroundColor Green
        Add-ValidationResult -Name "Network Security Group" -Result "PASS" -Message ("NSG found: {0}" -f $nsgName)
    }
    else {
        Write-Host ("[FAIL] NSG missing: {0}" -f $nsgName) -ForegroundColor Red
        Add-ValidationResult -Name "Network Security Group" -Result "FAIL" -Message ("NSG missing: {0}" -f $nsgName)
    }
}

Write-Host "Checking Storage Account configuration..."

$storagePattern = "st{0}{1}{2}" -f $App, $Environment, $Region
$storage = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue |
    Where-Object { $_.StorageAccountName -like "$storagePattern*" }

if ($storage) {
    Write-Host ("[PASS] Storage Account found: {0}" -f $storage.StorageAccountName) -ForegroundColor Green
    Add-ValidationResult -Name "Storage Account" -Result "PASS" -Message ("Storage Account found: {0}" -f $storage.StorageAccountName)
}
else {
    Write-Host "[FAIL] Storage Account missing." -ForegroundColor Red
    Add-ValidationResult -Name "Storage Account" -Result "FAIL" -Message "Storage Account missing."
}

Write-Host "Checking Key Vault..."

$keyVaultName = "kv-{0}-{1}-{2}" -f $App, $Environment, $Region
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Write-Host ("[PASS] Key Vault found: {0}" -f $keyVaultName) -ForegroundColor Green
    Add-ValidationResult -Name "Key Vault" -Result "PASS" -Message ("Key Vault found: {0}" -f $keyVaultName)
}
else {
    Write-Host ("[FAIL] Key Vault missing: {0}" -f $keyVaultName) -ForegroundColor Red
    Add-ValidationResult -Name "Key Vault" -Result "FAIL" -Message ("Key Vault missing: {0}" -f $keyVaultName)
}

Write-Host "Checking Log Analytics Workspace..."

$lawName = "law-{0}-{1}-{2}" -f $App, $Environment, $Region
$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $lawName -ErrorAction SilentlyContinue

if ($law) {
    Write-Host ("[PASS] Log Analytics Workspace found: {0}" -f $lawName) -ForegroundColor Green
    Add-ValidationResult -Name "Log Analytics Workspace" -Result "PASS" -Message ("Log Analytics Workspace found: {0}" -f $lawName)
}
else {
    Write-Host ("[FAIL] Log Analytics Workspace missing: {0}" -f $lawName) -ForegroundColor Red
    Add-ValidationResult -Name "Log Analytics Workspace" -Result "FAIL" -Message ("Log Analytics Workspace missing: {0}" -f $lawName)
}

Write-Host "Checking Application Insights..."

$appInsightsName = "appi-{0}-{1}-{2}" -f $App, $Environment, $Region
$appInsights = Get-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $appInsightsName -ErrorAction SilentlyContinue

if ($appInsights) {
    Write-Host ("[PASS] Application Insights found: {0}" -f $appInsightsName) -ForegroundColor Green
    Add-ValidationResult -Name "Application Insights" -Result "PASS" -Message ("Application Insights found: {0}" -f $appInsightsName)
}
else {
    Write-Host ("[FAIL] Application Insights missing: {0}" -f $appInsightsName) -ForegroundColor Red
    Add-ValidationResult -Name "Application Insights" -Result "FAIL" -Message ("Application Insights missing: {0}" -f $appInsightsName)
}

Write-Host "Checking App Service..."

$appServiceName = "app-{0}-{1}-{2}" -f $App, $Environment, $Region
$appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $appServiceName -ErrorAction SilentlyContinue

if ($appService) {
    Write-Host ("[PASS] App Service found: {0}" -f $appServiceName) -ForegroundColor Green
    Add-ValidationResult -Name "App Service" -Result "PASS" -Message ("App Service found: {0}" -f $appServiceName)

    if ($appService.HttpsOnly -eq $true) {
        Write-Host "[PASS] App Service HTTPS-only is enabled." -ForegroundColor Green
        Add-ValidationResult -Name "App Service HTTPS" -Result "PASS" -Message "App Service HTTPS-only is enabled."
    }
    else {
        Write-Host "[FAIL] App Service HTTPS-only is not enabled." -ForegroundColor Red
        Add-ValidationResult -Name "App Service HTTPS" -Result "FAIL" -Message "App Service HTTPS-only is not enabled."
    }

    if ($appService.Identity -and $appService.Identity.Type) {
        Write-Host ("[PASS] Managed Identity configured: {0}" -f $appService.Identity.Type) -ForegroundColor Green
        Add-ValidationResult -Name "App Service Managed Identity" -Result "PASS" -Message ("Managed Identity configured: {0}" -f $appService.Identity.Type)
    }
    else {
        Write-Host "[WARN] Managed Identity not configured on App Service." -ForegroundColor Yellow
        Add-ValidationResult -Name "App Service Managed Identity" -Result "WARN" -Message "Managed Identity not configured on App Service."
    }
}
else {
    Write-Host ("[FAIL] App Service missing: {0}" -f $appServiceName) -ForegroundColor Red
    Add-ValidationResult -Name "App Service" -Result "FAIL" -Message ("App Service missing: {0}" -f $appServiceName)
}

$report = [PSCustomObject]@{
    Environment       = $Environment
    Application       = $App
    Region            = $Region
    Location          = $Location
    ResourceGroupName = $ResourceGroupName
    VNetName          = $VNetName
    Status            = "Completed"
    GeneratedAt       = (Get-Date).ToString("s")
    Checks            = $validationResults
}

$reportPath = Join-Path $PSScriptRoot "validation-report.json"
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding utf8

if (Test-Path $reportPath) {
    Write-Host ("[PASS] Validation report generated: {0}" -f $reportPath) -ForegroundColor Green
}
else {
    Write-Host "[FAIL] Validation report was not generated." -ForegroundColor Red
}

Write-Host ""
Write-Host "Validation summary:"
$validationResults | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================="
Write-Host "VALIDATION AUDIT COMPLETED"
Write-Host "============================================="
Write-Host ""
Write-Host ("Validation report written to: {0}" -f $reportPath)
Write-Host "Review PASS, WARN, FAIL, and SKIP results above for environment compliance status."
