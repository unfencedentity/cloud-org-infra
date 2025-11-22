<#
.SYNOPSIS
  Creates or ensures an App Service Plan + Web App with Managed Identity.

.DESCRIPTION
  This script provisions the compute layer for the cloud-org-infra project:
    - App Service Plan (plan-core-weu)
    - Web App (app-core-weu)
    - System-assigned Managed Identity
    - Standard tags (owner/env/app)

  It is idempotent: safe to run multiple times.
#>

[CmdletBinding()]
param(
    [string]$Environment        = "dev",
    [string]$Location           = "westeurope",
    [string]$ResourceGroupName  = "rg-dev-weu",
    [string]$Owner              = "lucian"
)

Write-Host "=== App Service deployment for environment: $Environment ===" -ForegroundColor Cyan

# Names
$appServicePlanName = "plan-core-weu"
$webAppName         = "app-core-weu"

# Tags
$tags = @{
    owner = $Owner
    env   = $Environment
    app   = "core"
}

# 1. Ensure Resource Group exists
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource Group '$ResourceGroupName' not found. Creating it..." -ForegroundColor Yellow
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $tags
} else {
    Write-Host "Resource Group '$ResourceGroupName' already exists." -ForegroundColor Yellow
}

# 2. Ensure App Service Plan
$appServicePlan = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if ($appServicePlan) {
    Write-Host "App Service Plan '$appServicePlanName' already exists." -ForegroundColor Yellow
} else {
    Write-Host "Creating App Service Plan '$appServicePlanName'..." -ForegroundColor Green
    $appServicePlan = New-AzAppServicePlan `
        -Name $appServicePlanName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Tier "B1" `
        -NumberofWorkers 1 `
        -WorkerSize "Small"
}

# 3. Ensure Web App
$webApp = Get-AzWebApp -Name $webAppName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if ($webApp) {
    Write-Host "Web App '$webAppName' already exists." -ForegroundColor Yellow
} else {
    Write-Host "Creating Web App '$webAppName'..." -ForegroundColor Green
    $webApp = New-AzWebApp `
        -Name $webAppName `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AppServicePlan $appServicePlanName
}

# 4. Ensure Managed Identity is enabled on Web App
if (-not $webApp.Identity -or -not $webApp.Identity.Type -or $webApp.Identity.Type -ne "SystemAssigned") {
    Write-Host "Enabling system-assigned Managed Identity on Web App '$webAppName'..." -ForegroundColor Green
    $null = Set-AzWebApp `
        -Name $webAppName `
        -ResourceGroupName $ResourceGroupName `
        -AssignIdentity
    $webApp = Get-AzWebApp -Name $webAppName -ResourceGroupName $ResourceGroupName
} else {
    Write-Host "Web App '$webAppName' already has a system-assigned Managed Identity." -ForegroundColor Yellow
}

# 5. Apply tags to App Service Plan and Web App (where supported)
try {
    Write-Host "Applying tags to App Service Plan..." -ForegroundColor Green
    Set-AzResource `
        -ResourceId $appServicePlan.Id `
        -Tag $tags `
        -Force | Out-Null
} catch {
    Write-Host "Warning: Failed to apply tags to App Service Plan: $($_.Exception.Message)" -ForegroundColor Yellow
}

try {
    Write-Host "Applying tags to Web App..." -ForegroundColor Green
    $webAppResource = Get-AzResource -ResourceId $webApp.Id -ErrorAction SilentlyContinue
    if ($webAppResource) {
        Set-AzResource `
            -ResourceId $webApp.Id `
            -Tag $tags `
            -Force | Out-Null
    }
} catch {
    Write-Host "Warning: Failed to apply tags to Web App: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. Summary
Write-Host ""
Write-Host "=== App Service Summary ===" -ForegroundColor Cyan
Write-Host "Plan Name : $($appServicePlan.Name)"
Write-Host "Web App   : $($webApp.Name)"
Write-Host "RG        : $ResourceGroupName"
Write-Host "Location  : $Location"
Write-Host "MI Type   : $($webApp.Identity.Type)"
Write-Host ""
Write-Host "=== App Service deployment complete ===" -ForegroundColor Green
