[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$AppServicePlanSku = "B1",

    # Windows or Linux (for now we assume Windows, but keep this for future extension)
    [Parameter(Mandatory = $false)][ValidateSet("Windows", "Linux")]
    [string]$RuntimeStack = "Windows"
)

$ErrorActionPreference = "Stop"

# Naming conventions
$rgName        = "rg-$App-$Environment-$Region"
$appServicePlanName = "asp-$App-$Environment-$Region"
$webAppName    = "app-$App-$Environment-$Region"

# Basic tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Validate Resource Group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# --------------------------------------------------------------------
# App Service Plan
# --------------------------------------------------------------------
$plan = Get-AzAppServicePlan -Name $appServicePlanName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

if ($plan) {
    Write-Host "App Service Plan '$appServicePlanName' already exists in resource group '$rgName'."
}
else {
    if (-not $PSCmdlet.ShouldProcess("App Service Plan $appServicePlanName", "Create")) { return }

    Write-Host "Creating App Service Plan '$appServicePlanName' (SKU=$AppServicePlanSku) in '$Location'..."

    $plan = New-AzAppServicePlan `
        -Name $appServicePlanName `
        -ResourceGroupName $rgName `
        -Location $Location `
        -Tier $AppServicePlanSku `
        -NumberOfWorkers 1

    Write-Host "App Service Plan '$appServicePlanName' created."
}

# --------------------------------------------------------------------
# Web App
# --------------------------------------------------------------------
$webApp = Get-AzWebApp -Name $webAppName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

if ($webApp) {
    Write-Host "Web App '$webAppName' already exists in resource group '$rgName'."
    return $webApp
}

if (-not $PSCmdlet.ShouldProcess("Web App $webAppName", "Create")) { return }

Write-Host "Creating Web App '$webAppName' in App Service Plan '$appServicePlanName'..."

$webApp = New-AzWebApp `
    -Name $webAppName `
    -ResourceGroupName $rgName `
    -Location $Location `
    -AppServicePlan $appServicePlanName

Write-Host "Web App '$webAppName' created."

return $webApp
