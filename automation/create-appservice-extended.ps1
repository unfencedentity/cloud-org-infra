# File: automation/create-appservice-extended.ps1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Defaults for enterprise settings
    [Parameter(Mandatory = $false)][bool]$EnableHTTPSOnly = $true,
    [Parameter(Mandatory = $false)][string]$MinimumTLSVersion = "1.2",
    [Parameter(Mandatory = $false)][bool]$EnableIdentity = $true,
    [Parameter(Mandatory = $false)][bool]$EnableAlwaysOn = $true
)

$ErrorActionPreference = "Stop"

# Naming conventions
$rgName        = "rg-$App-$Environment-$Region"
$appServicePlanName = "asp-$App-$Environment-$Region"
$webAppName    = "app-$App-$Environment-$Region"
$appInsightsName = "appi-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"

# Tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Validate RG
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first." }

# Get Web App
$webApp = Get-AzWebApp -Name $webAppName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if (-not $webApp) { throw "Web App '$webAppName' does not exist. Run create-appservice.ps1 first." }

# Get App Insights (needed for app settings)
$appInsights = Get-AzApplicationInsights -Name $appInsightsName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if (-not $appInsights) { throw "Application Insights '$appInsightsName' does not exist. Run create-appinsights.ps1 first." }

# --------------------------------------------------------------------
# Update App Settings (InstrumentationKey + ConnectionString)
# --------------------------------------------------------------------
$appSettingsToApply = @{
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = $appInsights.InstrumentationKey
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = $appInsights.ConnectionString
}

if ($PSCmdlet.ShouldProcess("Web App $webAppName", "Update Application Insights settings")) {
    Set-AzWebApp -Name $webAppName `
                 -ResourceGroupName $rgName `
                 -AppSettings $appSettingsToApply | Out-Null

    Write-Host "Updated App Insights settings for '$webAppName'."
}

# --------------------------------------------------------------------
# HTTPS Only
# --------------------------------------------------------------------
if ($EnableHTTPSOnly) {
    if ($PSCmdlet.ShouldProcess("Web App $webAppName", "Enable HTTPS Only")) {
        Set-AzWebApp -Name $webAppName `
                     -ResourceGroupName $rgName `
                     -HttpsOnly $true | Out-Null

        Write-Host "Enabled HTTPS Only for '$webAppName'."
    }
}

# --------------------------------------------------------------------
# Minimum TLS version
# --------------------------------------------------------------------
if ($PSCmdlet.ShouldProcess("Web App $webAppName", "Set TLS Version")) {
    Set-AzWebApp -Name $webAppName `
                 -ResourceGroupName $rgName `
                 -MinTlsVersion $MinimumTLSVersion | Out-Null

    Write-Host "Set minimum TLS version to $MinimumTLSVersion for '$webAppName'."
}

# --------------------------------------------------------------------
# Enable Managed Identity
# --------------------------------------------------------------------
if ($EnableIdentity) {
    if ($PSCmdlet.ShouldProcess("Web App $webAppName", "Enable Managed Identity")) {
        $identity = Set-AzWebApp -Name $webAppName `
                                 -ResourceGroupName $rgName `
                                 -AssignIdentity $true

        Write-Host "Enabled System Assigned Managed Identity for '$webAppName'."
    }
}

# --------------------------------------------------------------------
# Always On
# --------------------------------------------------------------------
if ($EnableAlwaysOn) {
    if ($PSCmdlet.ShouldProcess("Web App $webAppName", "Enable Always On")) {
        Set-AzWebApp -Name $webAppName `
                     -ResourceGroupName $rgName `
                     -AlwaysOn $true | Out-Null

        Write-Host "Enabled Always On for '$webAppName'."
    }
}

# --------------------------------------------------------------------
#  Diagnostic Logs -> (optional)
# --------------------------------------------------------------------
# NOTE:
# Diagnostic settings for the Web App (routing logs and metrics to
# Log Analytics) can be configured separately using Az.Monitor
# diagnostic settings if required.
# This module currently focuses on HTTPS, TLS, Managed Identity
# and Always On configuration for enterprise-grade hardening.

Write-Host "Extended App Service configuration completed for '$webAppName'."

return Get-AzWebApp -Name $webAppName -ResourceGroupName $rgName

Write-Host "Extended App Service configuration completed for '$webAppName'."

return Get-AzWebApp -Name $webAppName -ResourceGroupName $rgName
