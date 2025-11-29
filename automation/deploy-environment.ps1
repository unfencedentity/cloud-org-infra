param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = "Stop"

Write-Host ("Starting full deployment for Env={0} App={1} Region={2} Location={3}" -f `
    $Environment, $App, $Region, $Location)

function Ensure-AzContext {
    param(
        [string]$SubscriptionId
    )

    $ctx = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            $sec  = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)

            Connect-AzAccount -ServicePrincipal `
                              -Tenant       $env:AZURE_TENANT_ID `
                              -Credential   $cred `
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

$rgScript             = Join-Path $PSScriptRoot "create-rg.ps1"
$networkScript        = Join-Path $PSScriptRoot "create-network.ps1"
$nsgScript            = Join-Path $PSScriptRoot "create-nsgs.ps1"
$storageScript        = Join-Path $PSScriptRoot "create-storage.ps1"
$keyVaultScript       = Join-Path $PSScriptRoot "create-keyvault.ps1"
$appServiceScript     = Join-Path $PSScriptRoot "create-appservice.ps1"
$logAnalyticsScript   = Join-Path $PSScriptRoot "create-loganalytics.ps1"

if (-not (Test-Path $rgScript)) {
    throw ("Sub-script not found: {0}" -f $rgScript)
}

if (-not (Test-Path $networkScript)) {
    Write-Warning ("Sub-script not found: {0}. Network step will be skipped." -f $networkScript)
}

if (-not (Test-Path $nsgScript)) {
    Write-Warning ("Sub-script not found: {0}. NSG step will be skipped." -f $nsgScript)
}

if (-not (Test-Path $storageScript)) {
    Write-Warning ("Sub-script not found: {0}. Storage step will be skipped." -f $storageScript)
}

if (-not (Test-Path $keyVaultScript)) {
    Write-Warning ("Sub-script not found: {0}. Key Vault step will be skipped." -f $keyVaultScript)
}

if (-not (Test-Path $appServiceScript)) {
    Write-Warning ("Sub-script not found: {0}. App Service step will be skipped." -f $appServiceScript)
}

if (-not (Test-Path $logAnalyticsScript)) {
    Write-Warning ("Sub-script not found: {0}. Log Analytics step will be skipped." -f $logAnalyticsScript)
}

# Resource Group
& $rgScript -Environment $Environment `
            -App         $App `
            -Region      $Region `
            -Location    $Location

# Network
if (Test-Path $networkScript) {
    & $networkScript -Environment $Environment `
                     -App         $App `
                     -Region      $Region `
                     -Location    $Location
}

# NSGs
if (Test-Path $nsgScript) {
    & $nsgScript -Environment $Environment `
                 -App         $App `
                 -Region      $Region `
                 -Location    $Location
}

# Storage
if (Test-Path $storageScript) {
    & $storageScript -Environment $Environment `
                     -App         $App `
                     -Region      $Region `
                     -Location    $Location
}

# Key Vault
if (Test-Path $keyVaultScript) {
    & $keyVaultScript -Environment $Environment `
                      -App         $App `
                      -Region      $Region `
                      -Location    $Location
}

# Log Analytics Workspace
if (Test-Path $logAnalyticsScript) {
    & $logAnalyticsScript -Environment $Environment `
                          -App         $App `
                          -Region      $Region `
                          -Location    $Location
}

# App Service
if (Test-Path $appServiceScript) {
    & $appServiceScript -Environment $Environment `
                        -App         $App `
                        -Region      $Region `
                        -Location    $Location
}

Write-Host "Orchestration complete (RG, Network, NSG, Storage, Key Vault, Log Analytics, App Service steps executed)."
