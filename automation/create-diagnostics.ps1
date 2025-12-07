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

$apiVersion = "2021-05-01-preview"

# -------------------------------
# Resolve RG + Workspace
# -------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "RG not found" }

$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) { throw "LAW not found" }

$workspaceId = $workspace.ResourceId

# -------------------------------
# ✅ FIXED REST FUNCTION
# -------------------------------
function Set-DiagnosticSettingREST {
    param(
        [string]$ResourceId,
        [string]$SettingName,
        [string]$WorkspaceId,
        [string]$ApiVersion
    )

    $url = "https://management.azure.com$ResourceId/providers/microsoft.insights/diagnosticSettings/$SettingName?api-version=$ApiVersion"

    $body = @{
        properties = @{
            workspaceId = $WorkspaceId
            logs = @(
                @{
                    categoryGroup = "allLogs"
                    enabled       = $true
                }
            )
            metrics = @(
                @{
                    category = "AllMetrics"
                    enabled  = $true
                }
            )
        }
    } | ConvertTo-Json -Depth 10

    $token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com/").Token

    Invoke-RestMethod `
        -Method Put `
        -Uri $url `
        -Headers @{ Authorization = "Bearer $token" } `
        -Body $body `
        -ContentType "application/json"
}

# -------------------------------
# Key Vault
# -------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Set-DiagnosticSettingREST `
        -ResourceId  $keyVault.ResourceId `
        -SettingName "diag-$keyVaultName" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion
}

# -------------------------------
# Storage
# -------------------------------
$storage = Get-AzStorageAccount -ResourceGroupName $rgName |
    Where-Object {
        $_.Tags["app"] -eq $App -and $_.Tags["environment"] -eq $Environment
    } | Select-Object -First 1

if ($storage) {
    Set-DiagnosticSettingREST `
        -ResourceId  $storage.Id `
        -SettingName "diag-$($storage.StorageAccountName)" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion
}

Write-Host "✅ Diagnostics configuration finished."