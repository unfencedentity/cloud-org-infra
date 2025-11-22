# AppService.psm1
# Reusable idempotent module for App Service deployment

function Ensure-AppServicePlan {
    param(
        [string]$Name,
        [string]$ResourceGroupName,
        [string]$Location,
        [string]$Sku,
        [hashtable]$Tags
    )

    Write-Host "==> Checking App Service Plan '$Name'..." -ForegroundColor Cyan

    $existing = Get-AzAppServicePlan -Name $Name -ResourceGroup $ResourceGroupName -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "App Service Plan exists. Updating tags..." -ForegroundColor Yellow
        Set-AzResource -ResourceId $existing.Id -Tag $Tags -Force | Out-Null
        return $existing
    }

    Write-Host "Creating App Service Plan '$Name'..." -ForegroundColor Green
    return New-AzAppServicePlan `
        -Name $Name `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Tier "Standard" `
        -WorkerSize "Small" `
        -Sku $Sku `
        -Tag $Tags
}

function Ensure-WebApp {
    param(
        [string]$Name,
        [string]$ResourceGroupName,
        [string]$PlanName,
        [string]$Location,
        [string]$Runtime,
        [hashtable]$Tags
    )

    Write-Host "==> Checking Web App '$Name'..." -ForegroundColor Cyan

    $existing = Get-AzWebApp -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host "Web App exists. Updating settings & tags..." -ForegroundColor Yellow
        Set-AzResource -ResourceId $existing.Id -Tag $Tags -Force | Out-Null
        return $existing
    }

    Write-Host "Creating Web App '$Name'..." -ForegroundColor Green
    return New-AzWebApp `
        -Name $Name `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -AppServicePlan $PlanName `
        -Runtime $Runtime `
        -Tag $Tags
}

Export-ModuleMember -Function Ensure-AppServicePlan, Ensure-WebApp
