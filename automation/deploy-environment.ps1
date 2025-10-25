# deploy-environment.ps1
# Deploys a full environment: RG + Network + Storage + App Service

param(
    [ValidateSet("dev","test","prod")]
    [string]$Env = "dev",
    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region = "weu",
    [string]$AppName = "core",
    [string]$Location = "westeurope"
)

Write-Host "🚀 Starting full deployment for $Env - $AppName ($Region)"

# Paths (assuming scripts are in the same folder)
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$rgScript      = Join-Path $base "create-rg.ps1"
$netScript     = Join-Path $base "create-network.ps1"
$storageScript = Join-Path $base "create-storage.ps1"
$appScript     = Join-Path $base "create-appservice.ps1"

# Execute scripts in order
& $rgScript -Env $Env -Region $Region -Name $AppName -Location $Location
& $netScript -Env $Env -Region $Region -AppName $AppName -Location $Location
& $storageScript -Env $Env -Region $Region -AppName $AppName -Location $Location
& $appScript -Env $Env -Region $Region -AppName $AppName -Location $Location

Write-Host "✅ Environment '$Env-$AppName' deployed successfully!"
