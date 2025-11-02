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

    # Do we have an active context already? (expected in GitHub Actions after azure/login)
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        # Fallback for local runs using service principal env vars
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            $sec  = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)
            Connect-AzAccount -ServicePrincipal -Tenant $env:AZURE_TENANT_ID -Credential $cred -Subscription $SubscriptionId | Out-Null
        } else {
            throw "No Azure context available. Run via azure/login or set SP env vars (AZURE_CLIENT_ID/SECRET/TENANT_ID)."
        }
    }

    if ($SubscriptionId) {
        Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
    }

    $ctx = Get-AzContext
    Write-Host "✔ Using subscription: $($ctx.Subscription.Id) - $($ctx.Subscription.Name)"
}

Ensure-AzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID

# --- Call sub-scripts (first: create RG)
$rgScript = Join-Path $PSScriptRoot "create-rg.ps1"
if (-not (Test-Path $rgScript)) {
    throw "Sub-script not found: $rgScript"
}

# Pass down parameters as needed by your sub-script
& $rgScript -Environment $Environment -App $App -Region $Region -Location $Location
