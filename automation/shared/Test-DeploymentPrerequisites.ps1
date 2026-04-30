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

    if ($context.Subscription.Id -ne $SubscriptionId) {
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

    Write-Host "Pre-deployment validation completed successfully." -ForegroundColor Green
}
