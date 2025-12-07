[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

Write-Host "Loading Az modules in create-diagnostics.ps1..."

# Make sure required modules are available
$requiredModules = @(
    "Az.Accounts",
    "Az.OperationalInsights",
    "Az.Resources",
    "Az.KeyVault",
    "Az.Storage"
)

foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Module '$mod' not found. Installing from PSGallery..."
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    }

    Write-Host "Importing module '$mod'..."
    Import-Module $mod -ErrorAction Stop
}

# --------------------------------------------------------------------
# Naming
# --------------------------------------------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

Write-Host "Configuring diagnostics for '$App' ($Environment/$Region)..."

# --------------------------------------------------------------------
# Validate Resource Group
# --------------------------------------------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# --------------------------------------------------------------------
# Resolve Log Analytics workspace
# --------------------------------------------------------------------
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Log Analytics workspace '$workspaceName' not found in '$rgName'. Run create-loganalytics.ps1 first."
}

$workspaceId = $workspace.ResourceId
Write-Host "Using LAW workspace '$($workspace.Name)' ($workspaceId)."

# Single place for the diagnostics API version
$apiVersion = "2021-05-01-preview"

# --------------------------------------------------------------------
# Helper: Create/Update Diagnostic Setting via Invoke-AzRestMethod
# --------------------------------------------------------------------
function Set-DiagnosticSettingREST {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ResourceId,
        [Parameter(Mandatory = $true)][string]$SettingName,
        [Parameter(Mandatory = $true)][string]$WorkspaceId,
        [Parameter(Mandatory = $true)][string]$ApiVersion
    )

    if (-not $ResourceId) {
        throw "Set-DiagnosticSettingREST: ResourceId is empty."
    }

    if (-not $ResourceId.StartsWith("/")) {
        throw "Set-DiagnosticSettingREST: ResourceId must be a full ARM id starting with '/subscriptions/...'. Got: '$ResourceId'"
    }

    # Path includes the api-version query explicitly
    $path = "$ResourceId/providers/microsoft.insights/diagnosticSettings/$SettingName?api-version=$ApiVersion"

    # Generic "all logs + all metrics" config
    $bodyObject = @{
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
    }

    $body = $bodyObject | ConvertTo-Json -Depth 10

    $debugUrl = "https://management.azure.com$path"
    Write-Host "PUT $debugUrl"
    Write-Host "SettingName: $SettingName"

    # Use Invoke-AzRestMethod so we reuse the Az authenticated context
    $result = Invoke-AzRestMethod `
        -Method Put `
        -Path $path `
        -Payload $body

    Write-Host "REST diagnostic setting applied: $SettingName"
    return $result
}

# --------------------------------------------------------------------
# Key Vault → LAW
# --------------------------------------------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Write-Host "Configuring diagnostics for Key Vault '$keyVaultName'..."
    Set-DiagnosticSettingREST `
        -ResourceId  $keyVault.ResourceId `
        -SettingName "diag-$keyVaultName" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion | Out-Null
}
else {
    Write-Warning "Key Vault '$keyVaultName' not found in resource group '$rgName'. Skipping KV diagnostics."
}

# --------------------------------------------------------------------
# Storage Account (tag-based discovery) → LAW
# --------------------------------------------------------------------
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue

$storage = $storageAccounts |
    Where-Object {
        $_.Tags["app"]         -eq $App       -and
        $_.Tags["environment"] -eq $Environment
    } |
    Select-Object -First 1

if ($storage) {
    Write-Host "Configuring diagnostics for Storage account '$($storage.StorageAccountName)'..."
    Set-DiagnosticSettingREST `
        -ResourceId  $storage.Id `
        -SettingName "diag-$($storage.StorageAccountName)" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion | Out-Null
}
else {
    Write-Warning "No tagged storage account for app='$App', env='$Environment' found in '$rgName'. Skipping storage diagnostics."
}

Write-Host "Diagnostics configuration complete for app='$App', env='$Environment', region='$Region'."

return @{
    Workspace     = $workspace
    KeyVaultName  = $keyVaultName
    ResourceGroup = $rgName
}