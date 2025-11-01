# automation/deploy-environment.ps1
# Deploy a full environment: RG + Network + Storage + App Service

[CmdletBinding()]
param(
    [ValidateSet("dev","test","prod")]
    [string]$Env,

    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region,

    [string]$AppName = "core",

    # Location Azure (e.g. westeurope). Keep both Region (short) + Location (ARM)
    [string]$Location = "westeurope"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host "🚀 Starting full deployment for Env=$Env  App=$AppName  Region=$Region  Location=$Location" -ForegroundColor Cyan

# resolve paths relative to this script
$base = Split-Path -Parent $PSCommandPath  # equivalent with $PSScriptRoot in pwsh 7+
$rgScript      = Join-Path $base "create-rg.ps1"
$netScript     = Join-Path $base "create-network.ps1"
$storageScript = Join-Path $base "create-storage.ps1"
$appScript     = Join-Path $base "create-appservice.ps1"

# quick existence checks
@($rgScript,$netScript,$storageScript,$appScript) | ForEach-Object {
    if (-not (Test-Path $_)) { throw "Required child script missing: $_" }
}

# run in order
& $rgScript      -Env $Env -Region $Region -AppName $AppName -Location $Location
& $netScript     -Env $Env -Region $Region -AppName $AppName -Location $Location
& $storageScript -Env $Env -Region $Region -AppName $AppName -Location $Location
& $appScript     -Env $Env -Region $Region -AppName $AppName -Location $Location

Write-Host "✅ Environment '$Env-$AppName' deployed successfully!" -ForegroundColor Green
