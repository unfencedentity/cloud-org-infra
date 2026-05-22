param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\Test-DeploymentPrerequisites.ps1"
. "$PSScriptRoot\shared\New-DeploymentSummary.ps1"

Write-Host ("Starting full deployment for Env={0} App={1} Region={2} Location={3}" -f `
    $Environment, $App, $Region, $Location)

function Ensure-AzContext {
    param(
        [string]$SubscriptionId
    )

    $ctx = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            $sec = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)

            Connect-AzAccount -ServicePrincipal `
                -Tenant $env:AZURE_TENANT_ID `
                -Credential $cred `
                -Subscription $SubscriptionId | Out-Null
        }
        else {
            throw "No Azure context available. Run Connect-AzAccount or set SP environment variables."
        }
    }

    if ($SubscriptionId) {
        Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
    }

    $ctx = Get-AzContext
    Write-Host ("Using subscription: {0} - {1}" -f $ctx.Subscription.Id, $ctx.Subscription.Name)
}

Ensure-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID
Set-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID | Out-Null

Test-DeploymentPrerequisites `
    -EnvironmentName $Environment `
    -Location $Location `
    -SubscriptionId $env:AZURE_SUBSCRIPTION_ID `
    -ModulesPath "$PSScriptRoot"

$executedModules = @()
$skippedModules = @()

# Load scripts
$rgScript                 = Join-Path $PSScriptRoot "create-rg.ps1"
$networkScript            = Join-Path $PSScriptRoot "create-network.ps1"
$nsgScript                = Join-Path $PSScriptRoot "create-nsgs.ps1"
$storageScript            = Join-Path $PSScriptRoot "create-storage.ps1"
$keyVaultScript           = Join-Path $PSScriptRoot "create-keyvault.ps1"
$appServiceScript         = Join-Path $PSScriptRoot "create-appservice.ps1"
$logAnalyticsScript       = Join-Path $PSScriptRoot "create-loganalytics.ps1"
$appInsightsScript        = Join-Path $PSScriptRoot "create-appinsights.ps1"
$appServiceExtendedScript = Join-Path $PSScriptRoot "create-appservice-extended.ps1"
$alertsScript             = Join-Path $PSScriptRoot "create-alerts.ps1"
$rbacScript               = Join-Path $PSScriptRoot "create-rbac.ps1"
$diagnosticsScript        = Join-Path $PSScriptRoot "create-diagnostics.ps1"
$vmScript                 = Join-Path $PSScriptRoot "create-vm.ps1"
$dnsScript                = Join-Path $PSScriptRoot "create-dns.ps1"
$healthChecksScript       = Join-Path $PSScriptRoot "create-healthchecks.ps1"

# Validate sub-scripts exist
if (-not (Test-Path $rgScript)) {
    throw ("Sub-script not found: {0}" -f $rgScript)
}

if (-not (Test-Path $networkScript)) {
    Write-Warning ("Sub-script not found: {0}. Network step skipped." -f $networkScript)
    $skippedModules += "Network"
}

if (-not (Test-Path $nsgScript)) {
    Write-Warning ("Sub-script not found: {0}. NSG step skipped." -f $nsgScript)
    $skippedModules += "NSG"
}

if (-not (Test-Path $storageScript)) {
    Write-Warning ("Sub-script not found: {0}. Storage step skipped." -f $storageScript)
    $skippedModules += "Storage"
}

if (-not (Test-Path $keyVaultScript)) {
    Write-Warning ("Sub-script not found: {0}. Key Vault step skipped." -f $keyVaultScript)
    $skippedModules += "Key Vault"
}

if (-not (Test-Path $appServiceScript)) {
    Write-Warning ("Sub-script not found: {0}. App Service step skipped." -f $appServiceScript)
    $skippedModules += "App Service"
}

if (-not (Test-Path $logAnalyticsScript)) {
    Write-Warning ("Sub-script not found: {0}. Log Analytics step skipped." -f $logAnalyticsScript)
    $skippedModules += "Log Analytics"
}

if (-not (Test-Path $appInsightsScript)) {
    Write-Warning ("Sub-script not found: {0}. App Insights step skipped." -f $appInsightsScript)
    $skippedModules += "App Insights"
}

if (-not (Test-Path $appServiceExtendedScript)) {
    Write-Warning ("Sub-script not found: {0}. App Service Extended step skipped." -f $appServiceExtendedScript)
    $skippedModules += "App Service Extended"
}

if (-not (Test-Path $alertsScript)) {
    Write-Warning ("Sub-script not found: {0}. Alerts step skipped." -f $alertsScript)
    $skippedModules += "Alerts"
}

if (-not (Test-Path $rbacScript)) {
    Write-Warning ("Sub-script not found: {0}. RBAC step skipped." -f $rbacScript)
    $skippedModules += "RBAC"
}

if (-not (Test-Path $diagnosticsScript)) {
    Write-Warning ("Sub-script not found: {0}. Diagnostics step skipped." -f $diagnosticsScript)
    $skippedModules += "Diagnostics"
}

if (-not (Test-Path $vmScript)) {
    Write-Warning ("Sub-script not found: {0}. VM step skipped." -f $vmScript)
    $skippedModules += "VM"
}

if (-not (Test-Path $dnsScript)) {
    Write-Warning ("Sub-script not found: {0}. DNS step skipped." -f $dnsScript)
    $skippedModules += "DNS"
}

if (-not (Test-Path $healthChecksScript)) {
    Write-Warning ("Sub-script not found: {0}. Health checks skipped." -f $healthChecksScript)
    $skippedModules += "Health Checks"
}

# Resource Group
& $rgScript `
    -Environment $Environment `
    -App $App `
    -Region $Region `
    -Location $Location

$executedModules += "Resource Group"

# Network
if (Test-Path $networkScript) {
    & $networkScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "Network"
}

# NSGs
if (Test-Path $nsgScript) {
    & $nsgScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "NSG"
}

# Storage
if (Test-Path $storageScript) {
    & $storageScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "Storage"
}

# Key Vault
if (Test-Path $keyVaultScript) {
    & $keyVaultScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "Key Vault"
}

# Log Analytics Workspace
if (Test-Path $logAnalyticsScript) {
    & $logAnalyticsScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "Log Analytics"
}

# Central Diagnostics
if (Test-Path $diagnosticsScript) {
    & $diagnosticsScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "Diagnostics"
}

# App Service
if (Test-Path $appServiceScript) {
    & $appServiceScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "App Service"
}

# Application Insights
if (Test-Path $appInsightsScript) {
    & $appInsightsScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "App Insights"
}

# Extended App Service Configuration
if (Test-Path $appServiceExtendedScript) {
    & $appServiceExtendedScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "App Service Extended"
}

# Alerts
if (Test-Path $alertsScript) {
    & $alertsScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location `
        -AlertEmail "ops@example.com"

    $executedModules += "Alerts"
}

# RBAC
if (Test-Path $rbacScript) {
    & $rbacScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location `
        -ReaderObjectIds @() `
        -ContributorObjectIds @() `
        -KeyVaultSecretsUserObjectIds @()

    $executedModules += "RBAC"
}

# VM
if (Test-Path $vmScript) {
    & $vmScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    $executedModules += "VM"
}

# DNS
if (Test-Path $dnsScript) {
    & $dnsScript `
        -Environment $Environment `
        -App $App `
        -Region $Region

    $executedModules += "DNS"
}

# Health Checks final QA step
if (Test-Path $healthChecksScript) {
    Write-Host "Running environment health checks..."

    $healthResult = & $healthChecksScript `
        -Environment $Environment `
        -App $App `
        -Region $Region `
        -Location $Location

    Write-Host "Health checks completed."
    $executedModules += "Health Checks"

    if ($healthResult.Status -eq "Error") {
        Write-Error "Critical errors detected during health checks. Aborting deployment."
        exit 2
    }
}

New-DeploymentSummary `
    -EnvironmentName $Environment `
    -App $App `
    -Region $Region `
    -Location $Location `
    -ExecutedModules $executedModules `
    -SkippedModules $skippedModules `
    -Status "Success"

Write-Host "Orchestration complete."
