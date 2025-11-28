# TEST BRO


[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Environment = "dev",

    [Parameter(Mandatory = $false)]
    [string]$App = "core",

    [Parameter(Mandatory = $false)]
    [string]$Region = "weu",

    [Parameter(Mandatory = $false)]
    [string]$Location = "westeurope",

    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
)

# Fail fast
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host (" Starting full deployment " ) -ForegroundColor Cyan
Write-Host ("   Env      : {0}" -f $Environment)
Write-Host ("   App      : {0}" -f $App)
Write-Host ("   Region   : {0}" -f $Region)
Write-Host ("   Location : {0}" -f $Location)
Write-Host ("   Sub      : {0}" -f ($SubscriptionId -ne "" ? $SubscriptionId : "<not specified>"))
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Ensure-AzContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId
    )

    $ctx = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        # Prefer service principal for automation
        if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID) {
            Write-Host "No Az context found. Connecting with Service Principal..." -ForegroundColor Yellow

            $sec  = ConvertTo-SecureString $env:AZURE_CLIENT_SECRET -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential($env:AZURE_CLIENT_ID, $sec)

            Connect-AzAccount -ServicePrincipal `
                              -Tenant      $env:AZURE_TENANT_ID `
                              -Credential  $cred `
                              -Subscription $SubscriptionId | Out-Null
        }
        else {
            throw "No Azure context available and no Service Principal env vars set. 
Set AZURE_CLIENT_ID / AZURE_CLIENT_SECRET / AZURE_TENANT_ID / AZURE_SUBSCRIPTION_ID or run Connect-AzAccount before executing."
        }
    }

    if ($SubscriptionId) {
        Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
    }

    $ctx = Get-AzContext
    Write-Host ("Using subscription: {0} - {1}" -f $ctx.Subscription.Id, $ctx.Subscription.Name) -ForegroundColor Green
}

function Invoke-InfraStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ScriptName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Arguments
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName

    if (-not (Test-Path $scriptPath)) {
        Write-Warning ("[{0}] Script '{1}' not found at path '{2}'. Skipping step." -f $Name, $ScriptName, $scriptPath)
        return
    }

    Write-Host ""
    Write-Host ("=== [{0}] START ===" -f $Name) -ForegroundColor Cyan

    try {
        if ($Arguments) {
            & $scriptPath @Arguments
        }
        else {
            & $scriptPath
        }

        Write-Host ("=== [{0}] SUCCESS ===" -f $Name) -ForegroundColor Green
    }
    catch {
        Write-Error ("[{0}] FAILED: {1}" -f $Name, $_.Exception.Message)
        throw
    }
    finally {
        Write-Host ("=== [{0}] END ===" -f $Name) -ForegroundColor Cyan
        Write-Host ""
    }
}

# 1. Ensure context & subscription
Ensure-AzContext -SubscriptionId $SubscriptionId

# 2. Arguments comune pentru toate sub-scripts
$commonArgs = @{
    Environment = $Environment
    App         = $App
    Region      = $Region
    Location    = $Location
}

# 3. Orchestrare: pașii infrastructurii de bază
try {
    Invoke-InfraStep -Name "Resource Group" -ScriptName "create-rg.ps1"       -Arguments $commonArgs
    Invoke-InfraStep -Name "Network"        -ScriptName "create-network.ps1" -Arguments $commonArgs
    Invoke-InfraStep -Name "Network Security" -ScriptName "create-nsg.ps1"   -Arguments $commonArgs
    Invoke-InfraStep -Name "Storage"        -ScriptName "create-storage.ps1" -Arguments $commonArgs
    Invoke-InfraStep -Name "App Service"    -ScriptName "create-appservice.ps1" -Arguments $commonArgs
    Invoke-InfraStep -Name "Key Vault"      -ScriptName "create-keyvault.ps1"   -Arguments $commonArgs
    Invoke-InfraStep -Name "Log Analytics"  -ScriptName "create-law.ps1"        -Arguments $commonArgs

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host " Full environment deployment completed.   " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "##########################################" -ForegroundColor Red
    Write-Host " Deployment FAILED                         " -ForegroundColor Red
    Write-Host (" Error: {0}" -f $_.Exception.Message)       -ForegroundColor Red
    Write-Host "##########################################" -ForegroundColor Red
    throw
}
