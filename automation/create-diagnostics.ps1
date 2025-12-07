[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

Write-Host "Loading Az modules in create-diagnostics.ps1..."

$requiredModules = @(
    "Az.Accounts",
    "Az.OperationalInsights",
    "Az.Resources",
    "Az.KeyVault",
    "Az.Storage"
)
foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $mod -ErrorAction Stop
}

# -------------------------------
# Naming
# -------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

# Single source of truth for API version
$apiVersion = "2021-05-01-preview"

# -------------------------------
# Resolve RG + LAW
# -------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "Resource group '$rgName' not found." }

$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue
if (-not $workspace) { throw "Log Analytics workspace '$workspaceName' not found in '$rgName'." }

$workspaceId = $workspace.ResourceId
Write-Host "Using LAW: $workspaceId"

# -------------------------------
# Robust REST helper (UriBuilder)
# -------------------------------
function Set-DiagnosticSettingREST {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceId,
        [Parameter(Mandatory = $true)][string]$SettingName,
        [Parameter(Mandatory = $true)][string]$WorkspaceId,
        [Parameter(Mandatory = $true)][string]$ApiVersion
    )

    if (-not $ResourceId) { throw "Set-DiagnosticSettingREST: ResourceId is empty." }
    if (-not $SettingName) { throw "Set-DiagnosticSettingREST: SettingName is empty." }

    # Build the URL safely to guarantee ?api-version= is present
    $basePath = "https://management.azure.com$ResourceId/providers/microsoft.insights/diagnosticSettings/$SettingName"
    $uriBuilder = [System.UriBuilder]$basePath
    $qs = [System.Web.HttpUtility]::ParseQueryString("")
    $qs["api-version"] = $ApiVersion
    $uriBuilder.Query = $qs.ToString()
    $url = $uriBuilder.Uri.AbsoluteUri

    # Body: All logs + All metrics to LAW
    $body = @{
        properties = @{
            workspaceId = $WorkspaceId
            logs = @(@{ categoryGroup = "allLogs";  enabled = $true })
            metrics = @(@{ category      = "AllMetrics"; enabled = $true })
        }
    } | ConvertTo-Json -Depth 10

    $token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token

    # Guard + trace
    if ($url -notmatch '\?api-version=') { throw "Built URL missing api-version: $url" }
    Write-Host "PUT $url"
    Write-Host "SettingName: $SettingName"

    $result = Invoke-RestMethod -Method Put -Uri $url -Headers @{ Authorization = "Bearer $token" } -Body $body -ContentType "application/json"
    Write-Host "Applied diagnostic setting '$SettingName'."
    return $result
}

# -------------------------------
# Key Vault → LAW (if exists)
# -------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue
if ($keyVault) {
    Set-DiagnosticSettingREST -ResourceId $keyVault.ResourceId -SettingName "diag-$keyVaultName" -WorkspaceId $workspaceId -ApiVersion $apiVersion | Out-Null
} else {
    Write-Warning "Key Vault '$keyVaultName' not found in '$rgName'. Skipping KV diagnostics."
}

# -------------------------------
# Storage (first tagged match) → LAW
# -------------------------------
$storage = Get-AzStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue |
    Where-Object { $_.Tags["app"] -eq $App -and $_.Tags["environment"] -eq $Environment } |
    Select-Object -First 1

if ($storage) {
    Set-DiagnosticSettingREST -ResourceId $storage.Id -SettingName "diag-$($storage.StorageAccountName)" -WorkspaceId $workspaceId -ApiVersion $apiVersion | Out-Null
} else {
    Write-Warning "No tagged storage account for app='$App', env='$Environment' in RG '$rgName'. Skipping storage diagnostics."
}

Write-Host "✅ Diagnostics configuration complete."