[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Email address used for the primary action group receiver
    [Parameter(Mandatory = $false)][string]$AlertEmail = "alerts@cloud-org-infra.test"
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming
# --------------------------------------------------------------------
$rgName            = "rg-$App-$Environment-$Region"
$actionGroupName   = "ag-$App-$Environment-$Region"

# Action Groups **cannot** be created in regional locations like westeurope.
# Microsoft only supports "global" for this resource type.
$actionGroupLocation = "global"

Write-Host "Processing Action Group '$actionGroupName' in resource group '$rgName'..."

# --------------------------------------------------------------------
# Validate Resource Group
# --------------------------------------------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# --------------------------------------------------------------------
# Check if Action Group already exists (idempotent)
# --------------------------------------------------------------------
$existing = Get-AzActionGroup -Name $actionGroupName -ResourceGroup $rgName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "Action Group '$actionGroupName' already exists. Skipping creation."
    return $existing
}

# --------------------------------------------------------------------
# Create Action Group
# --------------------------------------------------------------------
if (-not $PSCmdlet.ShouldProcess("Action Group $actionGroupName", "Create")) {
    return
}

$actionGroupParams = @{
    Name              = $actionGroupName
    ResourceGroupName = $rgName
    Location          = $actionGroupLocation
    ShortName         = "ag$($App)"

    EmailReceiver     = @(
        @{
            Name                 = "primary-email"
            EmailAddress         = $AlertEmail
            UseCommonAlertSchema = $true
        }
    )
}

$ag = New-AzActionGroup @actionGroupParams

Write-Host "Action Group created: '$actionGroupName' in location '$actionGroupLocation'."
return $ag
