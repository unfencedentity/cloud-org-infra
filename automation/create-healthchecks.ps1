[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "          Azure Environment Health Check — Standard Scan" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment | App: $App | Region: $Region | Location: $Location"
Write-Host ""

# -------------------------------------------------------------
# Core Data Structure
# -------------------------------------------------------------

$HealthResults = @()
$GlobalScore = 100

function Add-HealthResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details,
        [int]$ScoreImpact
    )

    $result = [PSCustomObject]@{
        Name        = $Name
        Status      = $Status
        Details     = $Details
        ScoreImpact = $ScoreImpact
    }

    $script:HealthResults += $result
    $script:GlobalScore -= $ScoreImpact
}

# -------------------------------------------------------------
# Helper Color Output
# -------------------------------------------------------------

function Write-Status {
    param([string]$Message, [string]$Level)

    switch ($Level.ToUpper()) {
        "OK"       { Write-Host "[OK]       $Message" -ForegroundColor Green }
        "WARNING"  { Write-Host "[WARNING]  $Message" -ForegroundColor Yellow }
        "CRITICAL" { Write-Host "[CRITICAL] $Message" -ForegroundColor Red }
        default     { Write-Host "[INFO]     $Message" -ForegroundColor White }
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

# -------------------------------------------------------------
# Fetchers (centralized resource lookup)
# -------------------------------------------------------------

function Get-RG {
    $rgName = "rg-$App-$Environment-$Region"
    return Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
}

function Get-VNet {
    $vnetName = "vnet-$App-$Environment-$Region"
    $rg = Get-RG
    return Get-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
}

function Get-NSGs {
    $rg = Get-RG
    return Get-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
}

function Get-StorageAccounts {
    $rg = Get-RG
    return Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
}

function Get-KeyVault {
    $kvName = "kv-$App-$Environment-$Region"
    return Get-AzKeyVault -VaultName $kvName -ErrorAction SilentlyContinue
}

function Get-AppService {
    $rg = Get-RG
    $appName = "app-$App-$Environment-$Region"
    return Get-AzWebApp -Name $appName -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
}

function Get-AppInsights {
    $rg = Get-RG
    $aiName = "appi-$App-$Environment-$Region"
    return Get-AzApplicationInsights -ResourceGroupName $rg.ResourceGroupName -Name $aiName -ErrorAction SilentlyContinue
}

function Get-DiagnosticSettings {
    param([string]$ResourceId)
    return Get-AzDiagnosticSetting -ResourceId $ResourceId -ErrorAction SilentlyContinue
}

# -------------------------------------------------------------
# Scoring + Severity
# -------------------------------------------------------------

function Get-Severity {
    param([int]$Score)

    if ($Score -ge 90) { return "OK" }
    if ($Score -ge 70) { return "Warning" }
    return "Critical"
}

# -------------------------------------------------------------
# Start Execution
# -------------------------------------------------------------

Write-Host "Initializing resource discovery..." -ForegroundColor DarkGray

$ResourceGroup = Get-RG
$VirtualNetwork = Get-VNet
$NSGs = Get-NSGs
$StorageAccounts = Get-StorageAccounts
$KeyVault = Get-KeyVault
$AppService = Get-AppService
$AppInsights = Get-AppInsights

Write-Host "Resource discovery complete." -ForegroundColor DarkGray

# -------------------------------------------------------------
# Resource Group Check
# -------------------------------------------------------------
Write-Section "Resource Group"

if (-not $ResourceGroup) {
    Write-Status "Resource Group not found" "CRITICAL"
    Add-HealthResult -Name "ResourceGroup" -Status "CRITICAL" -Details "Resource group missing" -ScoreImpact 25
} else {
    Write-Status "Resource Group exists: $($ResourceGroup.ResourceGroupName)" "OK"
    Add-HealthResult -Name "ResourceGroup" -Status "OK" -Details "RG present" -ScoreImpact 0
}

# -------------------------------------------------------------
# Tags Check
# -------------------------------------------------------------
Write-Section "Tags"

$requiredTags = @("environment", "app", "region", "owner")
$missingTags = @()

foreach ($tag in $requiredTags) {
    if (-not $ResourceGroup.Tags.ContainsKey($tag)) {
        $missingTags += $tag
    }
}

if ($missingTags.Count -gt 0) {
    Write-Status "Missing tags: $($missingTags -join ', ')" "WARNING"
    Add-HealthResult -Name "Tags" -Status "WARNING" -Details "Missing: $($missingTags -join ', ')" -ScoreImpact 10
} else {
    Write-Status "All required tags present" "OK"
    Add-HealthResult -Name "Tags" -Status "OK" -Details "Tags valid" -ScoreImpact 0
}

# -------------------------------------------------------------
# VNet Check
# -------------------------------------------------------------
Write-Section "Virtual Network"

if (-not $VirtualNetwork) {
    Write-Status "VNet not found" "CRITICAL"
    Add-HealthResult -Name "VNet" -Status "CRITICAL" -Details "VNet missing" -ScoreImpact 20
} else {
    Write-Status "VNet found: $($VirtualNetwork.Name)" "OK"
    Add-HealthResult -Name "VNet" -Status "OK" -Details "VNet present" -ScoreImpact 0
}

# -------------------------------------------------------------
# Subnets Check
# -------------------------------------------------------------
Write-Section "Subnets"

if ($VirtualNetwork -and $VirtualNetwork.Subnets.Count -gt 0) {
    Write-Status "Subnets found: $($VirtualNetwork.Subnets.Count)" "OK"
    Add-HealthResult -Name "Subnets" -Status "OK" -Details "Subnets OK" -ScoreImpact 0
} else {
    Write-Status "No subnets found" "CRITICAL"
    Add-HealthResult -Name "Subnets" -Status "CRITICAL" -Details "Missing subnets" -ScoreImpact 15
}

# -------------------------------------------------------------
# NSG Check
# -------------------------------------------------------------
Write-Section "Network Security Groups"

if ($NSGs -and $NSGs.Count -gt 0) {
    Write-Status "NSGs found: $($NSGs.Count)" "OK"
    Add-HealthResult -Name "NSG" -Status "OK" -Details "NSGs OK" -ScoreImpact 0
} else {
    Write-Status "No NSGs found" "CRITICAL"
    Add-HealthResult -Name "NSG" -Status "CRITICAL" -Details "NSGs missing" -ScoreImpact 15
}

# -------------------------------------------------------------
# Storage Security Check
# -------------------------------------------------------------
Write-Section "Storage Accounts"

if ($StorageAccounts.Count -eq 0) {
    Write-Status "No Storage Accounts found" "WARNING"
    Add-HealthResult -Name "Storage" -Status "WARNING" -Details "Missing storage accounts" -ScoreImpact 10
} else {
    foreach ($st in $StorageAccounts) {
        if ($st.EnableHttpsTrafficOnly -eq $false) {
            Write-Status "HTTPS not enforced on $($st.StorageAccountName)" "CRITICAL"
            Add-HealthResult -Name "StorageSecurity" -Status "CRITICAL" -Details "HTTPS disabled" -ScoreImpact 20
        } else {
            Write-Status "HTTPS enforced on $($st.StorageAccountName)" "OK"
        }
    }

    Add-HealthResult -Name "Storage" -Status "OK" -Details "Security validated" -ScoreImpact 0
}

# -------------------------------------------------------------
# Key Vault Check
# -------------------------------------------------------------
Write-Section "Key Vault"

if (-not $KeyVault) {
    Write-Status "Key Vault not found" "CRITICAL"
    Add-HealthResult -Name "KeyVault" -Status "CRITICAL" -Details "KV missing" -ScoreImpact 20
} else {
    if ($KeyVault.EnablePurgeProtection -ne $true) {
        Write-Status "Purge protection DISABLED" "CRITICAL"
        Add-HealthResult -Name "KeyVault" -Status "CRITICAL" -Details "Purge protection disabled" -ScoreImpact 20
    } else {
        Write-Status "Purge protection enabled" "OK"
        Add-HealthResult -Name "KeyVault" -Status "OK" -Details "Secure" -ScoreImpact 0
    }
}

# -------------------------------------------------------------
# App Service Check
# -------------------------------------------------------------
Write-Section "App Service"

if (-not $AppService) {
    Write-Status "App Service missing" "CRITICAL"
    Add-HealthResult -Name "AppService" -Status "CRITICAL" -Details "Missing" -ScoreImpact 20
} else {
    if ($AppService.HttpsOnly -eq $false) {
        Write-Status "HTTPS disabled for App Service" "WARNING"
        Add-HealthResult -Name "AppService" -Status "WARNING" -Details "HTTPS disabled" -ScoreImpact 10
    } else {
        Write-Status "App Service HTTPS enforced" "OK"
        Add-HealthResult -Name "AppService" -Status "OK" -Details "Secure" -ScoreImpact 0
    }
}

# -------------------------------------------------------------
# App Insights Check
# -------------------------------------------------------------
Write-Section "Application Insights"

if (-not $AppInsights) {
    Write-Status "App Insights missing" "WARNING"
    Add-HealthResult -Name "AppInsights" -Status "WARNING" -Details "Missing" -ScoreImpact 10
} else {
    Write-Status "App Insights present" "OK"
    Add-HealthResult -Name "AppInsights" -Status "OK" -Details "Connected" -ScoreImpact 0
}

# -------------------------------------------------------------
# Diagnostics Check
# -------------------------------------------------------------
Write-Section "Diagnostics"

$missingDiagnostics = 0

$allDiagTargets = @(
    $VirtualNetwork,
    $KeyVault,
    $AppService
)

foreach ($res in $allDiagTargets) {
    if ($res -and $res.Id) {
        $diag = Get-DiagnosticSettings -ResourceId $res.Id

        if (-not $diag) {
            Write-Status "Diagnostics missing → $($res.Name)" "WARNING"
            $missingDiagnostics++
        }
    }
}

if ($missingDiagnostics -gt 0) {
    Add-HealthResult -Name "Diagnostics" -Status "WARNING" -Details "$missingDiagnostics resources missing diagnostics" -ScoreImpact 10
} else {
    Add-HealthResult -Name "Diagnostics" -Status "OK" -Details "All resources monitored" -ScoreImpact 0
    Write-Status "All diagnostics correctly configured" "OK"
}

# -------------------------------------------------------------
# Alerts Check
# -------------------------------------------------------------
Write-Section "Alerts"

$actionGroupName = "ag-$App-$Environment-$Region"

$ag = Get-AzActionGroup -Name $actionGroupName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

if (-not $ag) {
    Write-Status "Action Group missing" "WARNING"
    Add-HealthResult -Name "Alerts" -Status "WARNING" -Details "Action group missing" -ScoreImpact 10
} else {
    Write-Status "Action Group found" "OK"
    Add-HealthResult -Name "Alerts" -Status "OK" -Details "Alerts configured" -ScoreImpact 0
}

# -------------------------------------------------------------
# RBAC Check (Simplified)
# -------------------------------------------------------------
Write-Section "RBAC"

$assignments = Get-AzRoleAssignment -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

$unexpected = $assignments | Where-Object { $_.RoleDefinitionName -eq "Contributor" -and $_.ObjectId -notlike "*" }

if ($unexpected.Count -gt 0) {
    Write-Status "Unexpected Contributor assignments detected" "WARNING"
    Add-HealthResult -Name "RBAC" -Status "WARNING" -Details "Unexpected Contributor roles present" -ScoreImpact 10
} else {
    Write-Status "RBAC assignment structure OK" "OK"
    Add-HealthResult -Name "RBAC" -Status "OK" -Details "RBAC clean" -ScoreImpact 0
}

# =====================================================================
# BLOCK C — FINAL OUTPUT (JSON + HUMAN READABLE) + RETURN OBJECT
# =====================================================================

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                       HEALTH CHECK SUMMARY"
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------------------------------------
# Compute Final Severity
# -------------------------------------------------------------

$FinalSeverity = Get-Severity -Score $GlobalScore

switch ($FinalSeverity) {
    "OK"       { Write-Host "OVERALL STATUS: OK ($GlobalScore/100)" -ForegroundColor Green }
    "Warning"  { Write-Host "OVERALL STATUS: WARNING ($GlobalScore/100)" -ForegroundColor Yellow }
    "Critical" { Write-Host "OVERALL STATUS: CRITICAL ($GlobalScore/100)" -ForegroundColor Red }
}

Write-Host ""

# -------------------------------------------------------------
# Detailed Human-Readable Report
# -------------------------------------------------------------
Write-Section "Detailed Results"

foreach ($item in $HealthResults) {
    Write-Status "$($item.Name): $($item.Details)" $item.Status
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                      JSON SUMMARY (for automation)"
Write-Host "==================================================================" -ForegroundColor Cyan

# -------------------------------------------------------------
# Prepare JSON Return Object
# -------------------------------------------------------------

$JsonSummary = [PSCustomObject]@{
    Environment   = $Environment
    App           = $App
    Region        = $Region
    Location      = $Location
    Score         = $GlobalScore
    Severity      = $FinalSeverity
    Timestamp     = (Get-Date)
    Results       = $HealthResults
}

# Print JSON to console
$JsonSummary | ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "Health check completed." -ForegroundColor Cyan

# Return object for CI/CD or programmatic use
return $JsonSummary
