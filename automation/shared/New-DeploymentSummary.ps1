<#
.SYNOPSIS
Creates a centralized deployment summary after orchestration execution.

.DESCRIPTION
Generates a readable deployment report containing deployment metadata,
executed modules, skipped modules, and final execution status.

This provides operators with a quick post-run overview and improves
visibility during troubleshooting, validation, and deployment auditing.

.PARAMETER EnvironmentName
Target environment name.

.PARAMETER App
Application or workload name.

.PARAMETER Region
Short Azure region code.

.PARAMETER Location
Full Azure region.

.PARAMETER ExecutedModules
List of modules successfully executed.

.PARAMETER SkippedModules
List of modules skipped during orchestration.

.PARAMETER Status
Final deployment state.

.EXAMPLE
New-DeploymentSummary `
    -EnvironmentName "dev" `
    -App "core" `
    -Region "weu" `
    -Location "westeurope" `
    -ExecutedModules @("Resource Group","Network") `
    -SkippedModules @() `
    -Status "Success"
#>

function New-DeploymentSummary {
    param (
        [string]$EnvironmentName,
        [string]$App,
        [string]$Region,
        [string]$Location,
        [string[]]$ExecutedModules,
        [string[]]$SkippedModules,
        [string]$Status
    )

    Write-Host ""
    Write-Host "============================================="
    Write-Host "DEPLOYMENT SUMMARY REPORT"
    Write-Host "============================================="
    Write-Host ""

    Write-Host ("Environment : {0}" -f $EnvironmentName)
    Write-Host ("Application : {0}" -f $App)
    Write-Host ("Region      : {0}" -f $Region)
    Write-Host ("Location    : {0}" -f $Location)
    Write-Host ("Status      : {0}" -f $Status)

    Write-Host ""
    Write-Host "Executed modules:"

    if ($ExecutedModules -and $ExecutedModules.Count -gt 0) {
        foreach ($module in $ExecutedModules) {
            Write-Host (" - {0}" -f $module)
        }
    }
    else {
        Write-Host " - None"
    }

    Write-Host ""
    Write-Host "Skipped modules:"

    if ($SkippedModules -and $SkippedModules.Count -gt 0) {
        foreach ($module in $SkippedModules) {
            Write-Host (" - {0}" -f $module)
        }
    }
    else {
        Write-Host " - None"
    }

    Write-Host ""
    Write-Host "Centralized deployment summary generated successfully." -ForegroundColor Green
}
