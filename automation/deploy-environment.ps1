param(
    [string]$Environment = "dev",
    [string]$App         = "core",
    [string]$Region      = "weu",
    [string]$Location    = "westeurope"
)

$ErrorActionPreference = 'Stop'

Write-Host "🚀 Starting full deployment for Env=$Environment  App=$App  Region=$Region  Location=$Location"
Write-Host ""

function Ensure-AzContext {
    param([string]$SubscriptionId)

    # Do we have an active context already? (expected in GitHub Actions after azure/login)
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        # Fallback for local runs using service principal env vars
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            Write-Host "ℹ No Az context found, trying service principal from env vars..."
            $sec  = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)
            Connect-AzAccount -ServicePrincipal `
                -Tenant      $env:AZURE_TENANT_ID `
                -Credential  $cred `
                -Subscription $SubscriptionId | Out-Null
        }
        else {
            throw "No Azure context available. Run via azure/login or set SP env vars (AZURE_CLIENT_ID/SECRET/TENANT_ID)."
        }
    }

    if ($SubscriptionId) {
        Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
    }

    $ctx = Get-AzContext
    Write-Host "✔ Using subscription: $($ctx.Subscription.Id) - $($ctx.Subscription.Name)"
    Write-Host ""
}

# 1. Ensure we are logged in to the right subscription (for CI: env:AZURE_SUBSCRIPTION_ID)
Ensure-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID

# 2. Define the ordered list of sub-scripts that represent our infra
#    (these must exist in the same folder as this file)
$deploymentSteps = @(
    "create-rg.ps1",          # Resource Group
    "create-network.ps1",     # VNet + subnets + NSGs
    "create-storage.ps1",     # ADLS Gen2 storage
    "create-appservice.ps1"   # App Service Plan + Web App (noul script)
)

Write-Host "📜 Deployment steps:"
$deploymentSteps | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

# 3. Run each step in order, passing down the shared parameters
foreach ($step in $deploymentSteps) {

    $scriptPath = Join-Path $PSScriptRoot $step

    if (-not (Test-Path $scriptPath)) {
        Write-Warning "⚠ Sub-script not found: $scriptPath — skipping this step."
        continue
    }

    Write-Host "▶ Running $step ..."
    & $scriptPath -Environment $Environment -App $App -Region $Region -Location $Location

    if ($LASTEXITCODE -ne 0) {
        throw "❌ Step $step failed with exit code $LASTEXITCODE. Stopping deployment."
    }

    Write-Host "✔ Completed $step"
    Write-Host ""
}

Write-Host "✅ Full environment deployment finished for Env=$Environment / App=$App / Region=$Region"
