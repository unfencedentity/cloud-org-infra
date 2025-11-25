param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Starting full deployment for Env=$Environment  App=$App  Region=$Region  Location=$Location"

function Ensure-AzContext {
    param([string]$SubscriptionId)

    $ctx = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            $sec  = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)

            Connect-AzAccount `
                -ServicePrincipal `
                -Tenant $env:AZURE_TENANT_ID `
                -Credential $cred `
                -Subscription $SubscriptionId | Out-Null
        }
        else {
            throw "❌ No Azure context. Run Connect-AzAccount or configure SP env vars."
        }
    }

    if ($SubscriptionId) {
        Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
    }

    $ctx = Get-AzContext
    Write-Host "✔ Using subscription: $($ctx.Subscription.Id) - $($ctx.Subscription.Name)"
}

# --- Ensure AZ login ---
Ensure-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID

# --- Run sub-scripts in ORDER ---

# 1. Resource Group
$rgScript = Join-Path $PSScriptRoot "create-rg.ps1"
if (-not (Test-Path $rgScript)) { throw "Sub-script not found: $rgScript" }
& $rgScript -Environment $Environment -App $App -Region $Region -Location $Location

# 2. Network (optional)
$netScript = Join-Path $PSScriptRoot "create-network.ps1"
if (Test-Path $netScript) {
    & $netScript -Environment $Environment -App $App -Region $Region -Location $Location
    Write-Host "✔ Network created."
}
else {
    Write-Host "⚠ Network script not found, skipping."
}

# 3. Storage
$storageScript = Join-Path $PSScriptRoot "create-storage.ps1"
if (Test-Path $storageScript) {
    & $storageScript -Environment $Environment -App $App -Region $Region -Location $Location
    Write-Host "✔ Storage created."
}
else {
    Write-Host "⚠ Storage script not found, skipping."
}

# 4. App Service
$appSvcScript = Join-Path $PSScriptRoot "create-appservice.ps1"
if (Test-Path $appSvcScript) {
    & $appSvcScript -Environment $Environment -App $App -Region $Region -Location $Location
    Write-Host "✔ App Service created."
}
else {
    Write-Host "⚠ App Service script not found, skipping."
}

Write-Host ""
Write-Host "🌍 Full environment deployment completed successfully!" -ForegroundColor Green
