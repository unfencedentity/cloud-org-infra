
# File: automation/create-loganalytics.ps1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Pricing tier for Log Analytics (PerGB2018 is the standard pay-as-you-go tier)
    [Parameter(Mandatory = $false)][string]$WorkspaceSku = "PerGB2018",

    # Data retention in days (enterprise default: 30)
    [Parameter(Mandatory = $false)][int]$RetentionInDays = 7
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming conventions
# --------------------------------------------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"

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
# Log Analytics Workspace
# --------------------------------------------------------------------
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if ($workspace) {
    Write-Host "Log Analytics Workspace '$workspaceName' already exists in resource group '$rgName'."

    # Align retention with desired configuration
    if ($workspace.RetentionInDays -ne $RetentionInDays) {
        if ($PSCmdlet.ShouldProcess("Workspace $workspaceName", "Update retention from $($workspace.RetentionInDays) to $RetentionInDays days")) {
            Write-Host "Updating retention for Workspace '$workspaceName' to $RetentionInDays days..."

            Set-AzOperationalInsightsWorkspace `
                -ResourceGroupName $rgName `
                -Name $workspaceName `
                -RetentionInDays $RetentionInDays `
                -ErrorAction Stop `
            | Out-Null

            Write-Host "Retention for Workspace '$workspaceName' updated."
        }
    }

    # Return the latest workspace state
    return (Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name $workspaceName)
}

if (-not $PSCmdlet.ShouldProcess("Log Analytics Workspace $workspaceName", "Create")) { return }

Write-Host "Creating Log Analytics Workspace '$workspaceName' (SKU=$WorkspaceSku, Retention=$RetentionInDays days) in '$Location'..."

$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -Location $Location `
    -Sku $WorkspaceSku `
    -RetentionInDays $RetentionInDays `
    -Tag $tags `
    -ErrorAction Stop

Write-Host "Log Analytics Workspace '$workspaceName' created."

return $workspace
