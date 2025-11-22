<#
.SYNOPSIS
    Idempotent deployment for core App Service (Plan + Web App).

.DESCRIPTION
    Uses the reusable AppService module (Ensure-AppServicePlan / Ensure-WebApp)
    to create or update:
      - App Service Plan
      - Web App (Python 3.10, Managed Identity)
    Safe to run multiple times.

.NOTES
    Requires:
      - Az.Accounts
      - Az.Websites
      - automation/modules/AppService/AppService.psm1
#>

param(
    [string]$SubscriptionId = "",
    [string]$Environment    = "dev",
    [string]$Location       = "westeurope"
)

Write-Host "=== Core App Service deployment starting ===" -ForegroundColor Cyan

# 1. Connect to Azure / set subscription (optional for local runs)
try {
    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        Write-Host "No Azure context found. Running Connect-AzAccount..." -ForegroundColor Yellow
        Connect-AzAccount | Out-Null
    }

    if ($SubscriptionId -and $SubscriptionId.Trim() -ne "") {
        Write-Host "Setting subscription to $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
}
catch {
    Write-Host "ERROR: Failed to authenticate to Azure." -ForegroundColor Red
    throw
}

# 2. Global variables (adjust if you want)
$rgName        = "rg-dev-weu"
$appServicePlanName = "plan-core-weu"
$webAppName    = "app-core-weu"
$runtime       = "PYTHON|3.10"

$tags = @{
    env   = $Environment
    app   = "core"
    owner = "lucian"
}

Write-Host "`n--- Configuration ------------------------" -ForegroundColor DarkCyan
Write-Host "Resource Group : $rgName"
Write-Host "Location       : $Location"
Write-Host "Plan Name      : $appServicePlanName"
Write-Host "Web App        : $webAppName"
Write-Host "Runtime        : $runtime"
Write-Host "Tags           : $(($tags.GetEnumerator() | ForEach-Object { ""$($_.Key)=$($_.Value)"" }) -join ', ') )"
Write-Host "----------------------------------------`n" -ForegroundColor DarkCyan

# 3. Import AppService module
try {
    $modulePath = Join-Path $PSScriptRoot "modules/AppService/AppService.psm1"
    if (-not (Test-Path $modulePath)) {
        throw "Module not found at $modulePath. Make sure automation/modules/AppService/AppService.psm1 exists."
    }

    Write-Host "Importing AppService module from $modulePath" -ForegroundColor Cyan
    Import-Module $modulePath -Force
}
catch {
    Write-Host "ERROR: failed to import AppService module." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}

# 4. Ensure Resource Group exists (simple inline check)
try {
    Write-Host "`n==> Ensuring Resource Group '$rgName' exists..." -ForegroundColor Cyan
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating Resource Group '$rgName' in $Location..." -ForegroundColor Green
        $rg = New-AzResourceGroup -Name $rgName -Location $Location -Tag $tags
    }
    else {
        Write-Host "Resource Group already exists. Updating tags..." -ForegroundColor Yellow
        Set-AzResourceGroup -Name $rgName -Tag $tags | Out-Null
    }
}
catch {
    Write-Host "ERROR while ensuring Resource Group." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}

# 5. Provision App Service Plan (idempotent)
try {
    Write-Host "`n==> Ensuring App Service Plan '$appServicePlanName'..." -ForegroundColor Cyan
    $plan = Ensure-AppServicePlan `
        -Name $appServicePlanName `
        -ResourceGroupName $rgName `
        -Location $Location `
        -Sku "S1" `
        -Tags $tags

    Write-Host "App Service Plan ID: $($plan.Id)" -ForegroundColor DarkGreen
}
catch {
    Write-Host "ERROR while ensuring App Service Plan." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}

# 6. Provision Web App (idempotent)
try {
    Write-Host "`n==> Ensuring Web App '$webAppName'..." -ForegroundColor Cyan
    $web = Ensure-WebApp `
        -Name $webAppName `
        -ResourceGroupName $rgName `
        -PlanName $appServicePlanName `
        -Location $Location `
        -Runtime $runtime `
        -Tags $tags

    Write-Host "Web App URL: https://$($web.DefaultHostName)" -ForegroundColor DarkGreen
}
catch {
    Write-Host "ERROR while ensuring Web App." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    throw
}

# 7. Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   App Service deployment completed" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host " Resource Group : $rgName"
Write-Host " Location       : $Location"
Write-Host " Plan           : $appServicePlanName"
Write-Host " Web App        : $webAppName"
Write-Host " Runtime        : $runtime"
Write-Host " URL            : https://$($web.DefaultHostName)"
Write-Host " Tags           : $(($tags.GetEnumerator() | ForEach-Object { ""$($_.Key)=$($_.Value)"" }) -join ', ') )"
Write-Host "========================================`n" -ForegroundColor Cyan
