[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Default application type and kind for web applications
    [Parameter(Mandatory = $false)][string]$ApplicationType = "web",
    [Parameter(Mandatory = $false)][string]$Kind            = "web"
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming conventions
# --------------------------------------------------------------------
$rgName           = "rg-$App-$Environment-$Region"
$workspaceName    = "law-$App-$Environment-$Region"
$appInsightsName  = "appi-$App-$Environment-$Region"

# Basic tags
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# --------------------------------------------------------------------
# Validate Resource Group
# --------------------------------------------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# --------------------------------------------------------------------
# Validate Log Analytics Workspace
# --------------------------------------------------------------------
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Log Analytics Workspace '$workspaceName' does not exist in resource group '$rgName'. Run create-loganalytics.ps1 first."
}

$workspaceResourceId = $workspace.ResourceId

# --------------------------------------------------------------------
# Application Insights
# --------------------------------------------------------------------
$appInsights = Get-AzApplicationInsights `
    -ResourceGroupName $rgName `
    -Name $appInsightsName `
    -ErrorAction SilentlyContinue

if ($appInsights) {
    Write-Host "Application Insights '$appInsightsName' already exists in resource group '$rgName'."

    # Ensure it is linked to the expected Log Analytics Workspace
    if ($appInsights.WorkspaceResourceId -ne $workspaceResourceId) {
        if ($PSCmdlet.ShouldProcess("Application Insights $appInsightsName", "Update WorkspaceResourceId")) {
            Write-Host "Updating Application Insights '$appInsightsName' to use workspace '$workspaceName'..."

            Set-AzApplicationInsights `
                -ResourceGroupName   $rgName `
                -Name                $appInsightsName `
                -WorkspaceResourceId $workspaceResourceId `
                -ErrorAction Stop `
            | Out-Null

            Write-Host "Application Insights '$appInsightsName' updated to use workspace '$workspaceName'."
        }
    }

    # Return latest state
    return (Get-AzApplicationInsights -ResourceGroupName $rgName -Name $appInsightsName)
}

if (-not $PSCmdlet.ShouldProcess("Application Insights $appInsightsName", "Create")) { return }

Write-Host "Creating Application Insights '$appInsightsName' in '$Location' linked to workspace '$workspaceName'..."

$appInsights = New-AzApplicationInsights `
    -ResourceGroupName   $rgName `
    -Name                $appInsightsName `
    -Location            $Location `
    -Kind                $Kind `
    -ApplicationType     $ApplicationType `
    -WorkspaceResourceId $workspaceResourceId `
    -Tag                 $tags `
    -ErrorAction         Stop

Write-Host "Application Insights '$appInsightsName' created."

return $appInsights
