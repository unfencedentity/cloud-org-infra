[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Email for Alert Group
    [Parameter(Mandatory = $false)][string]$AlertEmail = "alerts@cloud-org-infra.test"
)

$ErrorActionPreference = "Stop"

# Naming
$rgName        = "rg-$App-$Environment-$Region"
$actionGroup   = "ag-$App-$Environment-$Region"

Write-Host "Creating Action Group '$actionGroup' in resource group '$rgName'..."

# Check RG
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist — run create-rg.ps1 first."
}

# Check if action group exists
$existing = Get-AzActionGroup -Name $actionGroup -ResourceGroup $rgName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "Action Group '$actionGroup' already exists. Skipping creation."
    return $existing
}

# ---------------------------------------------------------
# Create Action Group using ONLY parameters compatible with
# Az.Monitor version in GitHub Actions runners.
# ---------------------------------------------------------

if (-not $PSCmdlet.ShouldProcess("Action Group $actionGroup", "Create")) { return }

$actionGroupParams = @{
    Name                    = $actionGroup
    ResourceGroupName       = $rgName
    ShortName               = "ag$App"
    Location                = $Location
    EmailReceiver           = @(
        @{
            Name          = "primary-email"
            EmailAddress  = $AlertEmail
            UseCommonAlertSchema = $true
        }
    )
}

$ag = New-AzActionGroup @actionGroupParams

Write-Host "Action Group created: '$actionGroup'."
return $ag


# File: automation/create-alerts.ps1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Email recipients for alerts (optional but recommended)
    [Parameter(Mandatory = $false)][string[]]$AlertEmails = @(),

    # Thresholds (can be tuned per environment later)
    [Parameter(Mandatory = $false)][int]$CpuThreshold          = 80,
    [Parameter(Mandatory = $false)][int]$CpuDurationMinutes    = 5,
    [Parameter(Mandatory = $false)][int]$Http5xxThreshold      = 10,
    [Parameter(Mandatory = $false)][int]$Http5xxDurationMinutes = 5
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming conventions
# --------------------------------------------------------------------
$rgName            = "rg-$App-$Environment-$Region"
$webAppName        = "app-$App-$Environment-$Region"
$appInsightsName   = "appi-$App-$Environment-$Region"
$actionGroupName   = "ag-$App-$Environment-$Region"

# Basic tags (if needed later for tagging alerts/AG metadata)
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
# Validate Web App
# --------------------------------------------------------------------
$webApp = Get-AzWebApp -Name $webAppName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if (-not $webApp) {
    throw "Web App '$webAppName' does not exist. Run create-appservice.ps1 first."
}

# --------------------------------------------------------------------
# Ensure Action Group
# --------------------------------------------------------------------
$actionGroup = Get-AzActionGroup -ResourceGroupName $rgName -Name $actionGroupName -ErrorAction SilentlyContinue

if (-not $actionGroup) {
    if (-not $AlertEmails -or $AlertEmails.Count -eq 0) {
        Write-Warning "No AlertEmails provided and Action Group '$actionGroupName' does not exist. Skipping alert creation."
        return
    }

    if ($PSCmdlet.ShouldProcess("Action Group $actionGroupName", "Create")) {
        Write-Host "Creating Action Group '$actionGroupName' in resource group '$rgName'..."

        $receivers = @()
        foreach ($email in $AlertEmails) {
            $receiverName = ("email-{0}" -f $email.Replace("@", "_").Replace(".", "_"))
            $receivers += New-AzActionGroupReceiver `
                -EmailReceiver `
                -Name $receiverName `
                -EmailAddress $email
        }

        $actionGroup = New-AzActionGroup `
            -Name $actionGroupName `
            -ResourceGroupName $rgName `
            -ShortName ($actionGroupName.Substring(0, [Math]::Min(12, $actionGroupName.Length))) `
            -Receiver $receivers `
            -ErrorAction Stop

        Write-Host "Action Group '$actionGroupName' created."
    }
}
else {
    Write-Host "Action Group '$actionGroupName' already exists in resource group '$rgName'."
}

if (-not $actionGroup) {
    Write-Warning "No Action Group available. Skipping alert rules."
    return
}

$actionGroupId = $actionGroup.Id

# --------------------------------------------------------------------
# Helper: Create Metric Alert (idempotent-ish: skip if already exists)
# --------------------------------------------------------------------
function New-OrUpdate-MetricAlert {
    param(
        [string]$AlertName,
        [string]$Description,
        [string]$MetricName,
        [string]$Operator,
        [string]$TimeAggregation,
        [double]$Threshold,
        [int]$WindowMinutes,
        [int]$Severity
    )

    $existing = Get-AzMetricAlertRuleV2 -ResourceGroupName $rgName -Name $AlertName -ErrorAction SilentlyContinue

    $window = New-TimeSpan -Minutes $WindowMinutes
    $frequency = New-TimeSpan -Minutes 1

    $criteria = New-AzMetricAlertRuleV2Criteria `
        -MetricName $MetricName `
        -TimeAggregation $TimeAggregation `
        -Operator $Operator `
        -Threshold $Threshold

    if ($existing) {
        Write-Host "Metric alert '$AlertName' already exists. Leaving existing configuration unchanged."
        return $existing
    }

    if ($PSCmdlet.ShouldProcess("Metric Alert $AlertName", "Create")) {
        Write-Host "Creating metric alert '$AlertName' for metric '$MetricName'..."

        $alert = New-AzMetricAlertRuleV2 `
            -Name $AlertName `
            -ResourceGroupName $rgName `
            -WindowSize $window `
            -Frequency $frequency `
            -TargetResourceId $webApp.Id `
            -Condition $criteria `
            -Severity $Severity `
            -Description $Description `
            -ActionGroupId $actionGroupId `
            -ErrorAction Stop

        Write-Host "Metric alert '$AlertName' created."
        return $alert
    }
}

# --------------------------------------------------------------------
# CPU High Alert
# --------------------------------------------------------------------
$cpuAlertName = "alert-app-$App-$Environment-$Region-cpu-high"
New-OrUpdate-MetricAlert `
    -AlertName       $cpuAlertName `
    -Description     "CPU usage over ${CpuThreshold}% on App Service $webAppName." `
    -MetricName      "CpuPercentage" `
    -Operator        "GreaterThan" `
    -TimeAggregation "Average" `
    -Threshold       $CpuThreshold `
    -WindowMinutes   $CpuDurationMinutes `
    -Severity        2 | Out-Null

# --------------------------------------------------------------------
# HTTP 5xx Alert
# --------------------------------------------------------------------
$http5xxAlertName = "alert-app-$App-$Environment-$Region-http5xx"
New-OrUpdate-MetricAlert `
    -AlertName       $http5xxAlertName `
    -Description     "HTTP 5xx responses on App Service $webAppName above ${Http5xxThreshold} in selected window." `
    -MetricName      "Http5xx" `
    -Operator        "GreaterThan" `
    -TimeAggregation "Total" `
    -Threshold       $Http5xxThreshold `
    -WindowMinutes   $Http5xxDurationMinutes `
    -Severity        3 | Out-Null

Write-Host "Alerts configuration completed for App '$App' in environment '$Environment' (region '$Region')."
