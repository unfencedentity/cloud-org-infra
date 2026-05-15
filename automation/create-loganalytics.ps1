[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$Sku = "PerGB2018",
    [Parameter(Mandatory = $false)][int]$RetentionInDays = 30
)

$ErrorActionPreference = "Stop"

$rgName = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"

if ($Sku -eq "PerGB2018" -and $RetentionInDays -lt 30) {
    Write-Host "RetentionInDays '$RetentionInDays' is below the minimum supported value for SKU '$Sku'. Using 30 days instead."
    $RetentionInDays = 30
}

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

$existing = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host ("Log Analytics Workspace '{0}' already exists in resource group '{1}'. Skipping create." -f `
        $workspaceName, $rgName)

    return $existing
}

if (-not $PSCmdlet.ShouldProcess("Log Analytics Workspace $workspaceName", "Create")) {
    return
}

Write-Host ("Creating Log Analytics Workspace '{0}' (SKU={1}, Retention={2} days) in '{3}'..." -f `
    $workspaceName, $Sku, $RetentionInDays, $Location)

$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -Location $Location `
    -Sku $Sku `
    -RetentionInDays $RetentionInDays `
    -Tag $tags

Write-Host ("Log Analytics Workspace '{0}' created." -f $workspaceName)

return $workspace
