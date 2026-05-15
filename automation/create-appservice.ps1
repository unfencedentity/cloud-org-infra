[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$Runtime = "DOTNETCORE|8.0",
    [Parameter(Mandatory = $false)][string]$Sku = "B1"
)

$ErrorActionPreference = "Stop"

$rgName = "rg-$App-$Environment-$Region"
$appServicePlanName = "asp-$App-$Environment-$Region"

$baseString = "$App-$Environment-$Region"

$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)

$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

$webAppName = "app-$App-$Environment-$Region-$hash"
$webAppName = $webAppName.ToLower().Replace("-", "")

$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

$existingPlan = Get-AzAppServicePlan `
    -ResourceGroupName $rgName `
    -Name $appServicePlanName `
    -ErrorAction SilentlyContinue

if (-not $existingPlan) {
    if (-not $PSCmdlet.ShouldProcess("App Service Plan $appServicePlanName", "Create")) {
        return
    }

    Write-Host ("Creating App Service Plan '{0}' (SKU={1}) in '{2}'..." -f `
        $appServicePlanName, $Sku, $Location)

    $existingPlan = New-AzAppServicePlan `
        -ResourceGroupName $rgName `
        -Name $appServicePlanName `
        -Location $Location `
        -Tier "Basic" `
        -WorkerSize "Small" `
        -NumberofWorkers 1 `
        -Tag $tags

    Write-Host ("App Service Plan '{0}' created." -f $appServicePlanName)
}
else {
    Write-Host ("App Service Plan '{0}' already exists. Skipping create." -f `
        $appServicePlanName)
}

$existingWebApp = Get-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -ErrorAction SilentlyContinue

if ($existingWebApp) {
    Write-Host ("Web App '{0}' already exists. Skipping create." -f `
        $webAppName)

    return $existingWebApp
}

if (-not $PSCmdlet.ShouldProcess("Web App $webAppName", "Create")) {
    return
}

Write-Host ("Creating Web App '{0}' in App Service Plan '{1}'..." -f `
    $webAppName, $appServicePlanName)

$webApp = New-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -Location $Location `
    -AppServicePlan $appServicePlanName

Write-Host ("Web App '{0}' created." -f $webAppName)

return $webApp
