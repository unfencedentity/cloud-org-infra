[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

$rgName = "rg-$App-$Environment-$Region"

$baseString = "$App-$Environment-$Region"

$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)

$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

$webAppName = "app-$App-$Environment-$Region-$hash"
$webAppName = $webAppName.ToLower().Replace("-", "")

$appInsightsName = "appi-$App-$Environment-$Region"

$webApp = Get-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -ErrorAction SilentlyContinue

if (-not $webApp) {
    throw "Web App '$webAppName' does not exist. Run create-appservice.ps1 first."
}

$appInsights = Get-AzApplicationInsights `
    -ResourceGroupName $rgName `
    -Name $appInsightsName `
    -ErrorAction SilentlyContinue

if (-not $appInsights) {
    throw "Application Insights '$appInsightsName' does not exist. Run create-appinsights.ps1 first."
}

if (-not $PSCmdlet.ShouldProcess("Web App $webAppName", "Configure extended settings")) {
    return
}

Write-Host ("Configuring extended settings for Web App '{0}'..." -f `
    $webAppName)

$appSettings = @{
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = $appInsights.ConnectionString
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = $appInsights.InstrumentationKey
    "ASPNETCORE_ENVIRONMENT"                = $Environment.ToUpper()
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
}

Update-AzWebAppSetting `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -AppSettings $appSettings | Out-Null

Write-Host ("Extended configuration applied to Web App '{0}'." -f `
    $webAppName)

return Get-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName
