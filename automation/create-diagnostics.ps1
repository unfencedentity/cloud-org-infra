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
    "Az.Storage",
    "Az.Network",
    "Az.Websites"
)

foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "Module '$mod' not found. Installing from PSGallery..."
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    }

    Write-Host "Importing module '$mod'..."
    Import-Module $mod -ErrorAction Stop
}

$rgName         = "rg-$App-$Environment-$Region"
$workspaceName  = "law-$App-$Environment-$Region"
$keyVaultName   = "kv-$App-$Environment-$Region"
$vnetName       = "vnet-$App-$Environment-$Region"

$baseString = "$App-$Environment-$Region"

$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)

$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

$webAppName = "app-$App-$Environment-$Region-$hash"
$webAppName = $webAppName.ToLower().Replace("-", "")

Write-Host "Configuring diagnostics for '$App' ($Environment/$Region)..."

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Log Analytics workspace '$workspaceName' not found in '$rgName'. Run create-loganalytics.ps1 first."
}

$workspaceId = $workspace.ResourceId

Write-Host "Using LAW workspace '$($workspace.Name)' ($workspaceId)."

$apiVersion = "2021-05-01-preview"

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

    $path = "$ResourceId/providers/microsoft.insights/diagnosticSettings/$SettingName?api-version=$ApiVersion"

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

    $result = Invoke-AzRestMethod `
        -Method Put `
        -Path $path `
        -Payload $body

    Write-Host "REST diagnostic setting applied: $SettingName"

    return $result
}

# Key Vault discovery
$keyVault = Get-AzKeyVault `
    -ResourceGroupName $rgName `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Tags["app"] -eq $App -and
        $_.Tags["environment"] -eq $Environment
    } |
    Select-Object -First 1

if (-not $keyVault) {
    $keyVault = Get-AzKeyVault `
        -ResourceGroupName $rgName `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.VaultName -like "kv*$App*$Environment*$Region*"
        } |
        Select-Object -First 1
}

if ($keyVault) {
    Write-Host "Configuring diagnostics for Key Vault '$($keyVault.VaultName)'..."

    Set-DiagnosticSettingREST `
        -ResourceId  $keyVault.ResourceId `
        -SettingName "diag-$($keyVault.VaultName)" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion | Out-Null
}
else {
    Write-Warning "No Key Vault found in '$rgName'. Skipping Key Vault diagnostics."
}

# Storage Account
$storageAccounts = Get-AzStorageAccount `
    -ResourceGroupName $rgName `
    -ErrorAction SilentlyContinue

$storage = $storageAccounts |
    Where-Object {
        $_.Tags["app"] -eq $App -and
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

# Virtual Network
$vnet = Get-AzVirtualNetwork `
    -ResourceGroupName $rgName `
    -Name $vnetName `
    -ErrorAction SilentlyContinue

if ($vnet) {
    Write-Host "Configuring diagnostics for VNet '$vnetName'..."

    Set-DiagnosticSettingREST `
        -ResourceId  $vnet.Id `
        -SettingName "diag-$vnetName" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion | Out-Null
}
else {
    Write-Warning "VNet '$vnetName' not found in '$rgName'. Skipping VNet diagnostics."
}

# App Service
$webApp = Get-AzWebApp `
    -ResourceGroupName $rgName `
    -Name $webAppName `
    -ErrorAction SilentlyContinue

if ($webApp) {
    Write-Host "Configuring diagnostics for Web App '$webAppName'..."

    Set-DiagnosticSettingREST `
        -ResourceId  $webApp.Id `
        -SettingName "diag-$webAppName" `
        -WorkspaceId $workspaceId `
        -ApiVersion  $apiVersion | Out-Null
}
else {
    Write-Warning "Web App '$webAppName' not found in '$rgName'. Skipping App Service diagnostics."
}

Write-Host "Diagnostics configuration complete for app='$App', env='$Environment', region='$Region'."

return @{
    Workspace     = $workspace
    KeyVaultName  = if ($keyVault) { $keyVault.VaultName } else { $null }
    ResourceGroup = $rgName
    VNetName      = if ($vnet) { $vnet.Name } else { $null }
    WebAppName    = if ($webApp) { $webApp.Name } else { $null }
}