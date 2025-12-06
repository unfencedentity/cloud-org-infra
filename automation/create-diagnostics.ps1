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
    "Az.Monitor",
    "Az.OperationalInsights",
    "Az.Resources",
    "Az.Storage",
    "Az.KeyVault"
)

foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module $mod -ErrorAction Stop
}

# --------------------------------------------------------------------
# Naming & lookups
# --------------------------------------------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "Resource group '$rgName' does not exist." }

$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Log Analytics workspace '$workspaceName' not found."
}

Write-Host "Using workspace '$($workspace.Name)' (ResourceId: $($workspace.ResourceId))"

# --------------------------------------------------------------------
# Helper
# --------------------------------------------------------------------
function Ensure-DiagnosticSetting {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceId,
        [Parameter(Mandatory = $true)][string]$SettingName,
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.OperationalInsights.Models.PSWorkspace]$Workspace,
        [string]$ResourceFriendlyName
    )

    if (-not $ResourceFriendlyName) { $ResourceFriendlyName = $ResourceId }

    $existing = Get-AzDiagnosticSetting -ResourceId $ResourceId -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq $SettingName }

    if ($existing) {
        Write-Host "Diagnostic '$SettingName' already exists on $ResourceFriendlyName. Skipping."
        return
    }

    Write-Host "Creating diagnostic '$SettingName' on $ResourceFriendlyName..."

    $setCmd = Get-Command Set-AzDiagnosticSetting -ErrorAction SilentlyContinue
    $newCmd = Get-Command New-AzDiagnosticSetting -ErrorAction SilentlyContinue

    if ($setCmd) {
        # Modern module
        Set-AzDiagnosticSetting `
            -Name $SettingName `
            -ResourceId $ResourceId `
            -WorkspaceId $Workspace.ResourceId `
            -CategoryGroup @("AllLogs", "AllMetrics") `
            | Out-Null
    }
    elseif ($newCmd) {
        # Old module – NO -Enabled parameter
        New-AzDiagnosticSetting `
            -Name $SettingName `
            -ResourceId $ResourceId `
            -WorkspaceId $Workspace.ResourceId `
            -CategoryGroup @("AllLogs", "AllMetrics") `
            | Out-Null
    }
    else {
        throw "No diagnostic setting cmdlet available on this runner."
    }

    Write-Host "Diagnostic '$SettingName' created."
}

# --------------------------------------------------------------------
# Key Vault diagnostics
# --------------------------------------------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Ensure-DiagnosticSetting `
        -ResourceId $keyVault.ResourceId `
        -SettingName "diag-$keyVaultName" `
        -Workspace $workspace `
        -ResourceFriendlyName "Key Vault '$keyVaultName'"
}
else {
    Write-Warning "KV '$keyVaultName' not found. Skipping."
}

# --------------------------------------------------------------------
# Storage diagnostics
# --------------------------------------------------------------------
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue

$storage = $storageAccounts |
    Where-Object {
        $_.Tags["app"] -eq $App -and
        $_.Tags["environment"] -eq $Environment
    } |
    Select-Object -First 1

if ($storage) {
    Ensure-DiagnosticSetting `
        -ResourceId $storage.Id `
        -SettingName "diag-$($storage.StorageAccountName)" `
        -Workspace $workspace `
        -ResourceFriendlyName "Storage '$($storage.StorageAccountName)'"
}
else {
    Write-Warning "No tagged storage account found."
}

Write-Host "Diagnostics configuration complete."
