[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $false)][string]$MonitoringLocation
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\DeploymentNaming.ps1"
. "$PSScriptRoot\shared\ObjectShape.ps1"

$names = Get-DeploymentNames -Environment $Environment -App $App -Region $Region

$rgName = $names.ResourceGroupName
$webAppName = $names.WebAppName
$appInsightsName = $names.AppInsightsName

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

if (-not [string]::IsNullOrWhiteSpace($MonitoringLocation)) {
    Write-Host ("Using Application Insights '{0}' resolved by name/resource group (monitoring location target: {1})." -f $appInsightsName, $MonitoringLocation)
}

if (-not $PSCmdlet.ShouldProcess("Web App $webAppName", "Configure extended settings and enforce HTTPS")) {
    return
}

Write-Host ("Configuring extended settings for Web App '{0}'..." -f $webAppName)

$appInsightsResourceId = Get-ObjectPropertyValue -Object $appInsights -PropertyName "Id" -DefaultValue ""
if ([string]::IsNullOrWhiteSpace($appInsightsResourceId)) {
    $appInsightsResourceId = Get-ObjectPropertyValue -Object $appInsights -PropertyName "ResourceId" -DefaultValue ""
}

$appSettings = @{
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = (Get-ObjectPropertyValue -Object $appInsights -PropertyName "ConnectionString" -DefaultValue "")
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = (Get-ObjectPropertyValue -Object $appInsights -PropertyName "InstrumentationKey" -DefaultValue "")
    "APPLICATIONINSIGHTS_RESOURCE_ID"       = $appInsightsResourceId
    "ASPNETCORE_ENVIRONMENT"                = $Environment.ToUpper()
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
}

Set-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -AppSettings $appSettings `
    -HttpsOnly $true | Out-Null

Write-Host ("Extended configuration applied to Web App '{0}'." -f $webAppName)
Write-Host ("HTTPS enforcement enabled for Web App '{0}'." -f $webAppName)

return Get-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName
