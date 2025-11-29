[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Email address used for the main action group receiver
    [Parameter(Mandatory = $false)][string]$AlertEmail = "alerts@cloud-org-infra.test"
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming
# --------------------------------------------------------------------
$rgName       = "rg-$App-$Environment-$Region"
$actionGroup  = "ag-$App-$Environment-$Region"

Write-Host "Processing Action Group '$actionGroup' in resource group '$rgName'..."

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
$existing = Get-AzActionGroup -Name $actionGroup -ResourceGroup $rgName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "Action Group '$actionGroup' already exists. Skipping creation."
    return $existing
}

# --------------------------------------------------------------------
# Create Action Group (GitHub Actions–compatible syntax)
# --------------------------------------------------------------------
if (-not $PSCmdlet.ShouldProcess("Action Group $actionGroup", "Create")) {
    return
}

$actionGroupParams = @{
    Name              = $actionGroup
    ResourceGroupName = $rgName
    ShortName         = "ag$App"
    Location          = $Location
    EmailReceiver     = @(
        @{
            Name                 = "primary-email"
            EmailAddress         = $AlertEmail
            UseCommonAlertSchema = $true
        }
    )
}

$ag = New-AzActionGroup @actionGroupParams

Write-Host "Action Group created: '$actionGroup'."
return $ag
