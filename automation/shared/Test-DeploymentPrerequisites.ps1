<#
.SYNOPSIS
Performs prerequisite validation before Azure infrastructure deployment.

.DESCRIPTION
Validates critical deployment conditions before any provisioning logic is executed.

The function checks mandatory inputs, Azure authentication context, subscription alignment,
approved deployment regions, environment naming standards, and local automation path availability.

This acts as a deployment safety gate to reduce failed or unsafe infrastructure runs caused by
missing parameters, wrong Azure context, unsupported regions, or local script structure issues.

.PARAMETER EnvironmentName
Target environment name. Accepted values: dev, test, prod.

.PARAMETER Location
Azure region used for the deployment.

.PARAMETER SubscriptionId
Expected Azure subscription ID for the deployment run.

.PARAMETER ModulesPath
Local path that must exist before orchestration continues.

.EXAMPLE
Test-DeploymentPrerequisites `
    -EnvironmentName "dev" `
    -Location "westeurope" `
    -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -ModulesPath ".\automation"

.NOTES
This function should run before resource creation starts.
#>

function Test-DeploymentPrerequisites {
    param (
        [string]$EnvironmentName,
        [string]$Location,
        [string]$SubscriptionId,
        [string]$ModulesPath
    )

    Write-Host ""
    Write-Host "============================================="
    Write-Host "RUNNING PRE-DEPLOYMENT VALIDATION CHECKS"
    Write-Host "============================================="
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($EnvironmentName)) {
        throw "EnvironmentName parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($Location)) {
        throw "Location parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        throw "SubscriptionId parameter is missing."
    }

    if (-not (Test-Path $ModulesPath)) {
        throw "Modules path not found: $ModulesPath"
    }

    $context = Get-AzContext

    if (-not $context) {
        throw "No active Azure session detected. Run Connect-AzAccount first."
    }

    if ($null -eq $context.Subscription.Id -or $context.Subscription.Id -ne $SubscriptionId) {
        throw "Active Azure subscription does not match expected deployment subscription."
    }

    $validLocations = @(
        "westeurope",
        "northeurope",
        "uksouth",
        "eastus"
    )

    if ($Location -notin $validLocations) {
        throw "Location '$Location' is not in the approved deployment region list."
    }

    if ($EnvironmentName -notmatch '^(dev|test|prod)$') {
        throw "EnvironmentName must be dev, test, or prod."
    }

    Write-Host "Enterprise pre-deployment validation gate passed successfully." -ForegroundColor Green
}
