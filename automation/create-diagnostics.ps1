[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

# Ensure required Az modules are loaded (for GitHub Actions pwsh)
Import-Module Az.Monitor             -ErrorAction Stop
Import-Module Az.OperationalInsights -ErrorAction Stop
Import-Module Az.Resources           -ErrorAction Stop
Import-Module Az.Storage             -ErrorAction Stop
Import-Module Az.KeyVault            -ErrorAction Stop


Write-Host "Loading Az modules in create-diagnostics.ps1..."

# Import required Az modules (they are installed by the GitHub Actions workflow)
Import-Module Az.Accounts            -ErrorAction Stop
Import-Module Az.Resources           -ErrorAction Stop
Import-Module Az.OperationalInsights -ErrorAction Stop
Import-Module Az.Monitor             -ErrorAction Stop
Import-Module Az.KeyVault            -ErrorAction Stop
Import-Module Az.Storage             -ErrorAction Stop

# --------------------------------------------------------------------
# Naming & lookups
# --------------------------------------------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

Write-Host "Configuring central diagnostics for '$App' ($Environment/$Region)..."

# --------------------------------------------------------------------
# Validate Resource Group
# --------------------------------------------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

# --------------------------------------------------------------------
# Resolve Log Analytics workspace (central sink)
# --------------------------------------------------------------------
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Log Analytics workspace '$workspaceName' not found in '$rgName'. Run create-loganalytics.ps1 first."
}

Write-Host "Using Log Analytics workspace '$($workspace.Name)' (ResourceId: $($workspace.ResourceId))."

# --------------------------------------------------------------------
# Helper: ensure diagnostic setting on a resource
# --------------------------------------------------------------------
function Ensure-DiagnosticSetting {
    param(
        [Parameter(Mandatory = $true)][string]$ResourceId,
        [Parameter(Mandatory = $true)][string]$SettingName,
        [Parameter(Mandatory = $true)][object]$Workspace,
        [string]$ResourceFriendlyName
    )

    if (-not $ResourceFriendlyName) {
        $ResourceFriendlyName = $ResourceId
    }

    $existing = Get-AzDiagnosticSetting -ResourceId $ResourceId -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -eq $SettingName }

    if ($existing) {
        Write-Host "Diagnostic setting '$SettingName' already exists on $ResourceFriendlyName. Skipping."
        return $existing
    }

    if (-not $PSCmdlet.ShouldProcess($ResourceFriendlyName, "Configure diagnostic setting '$SettingName'")) {
        return
    }

    Write-Host "Creating diagnostic setting '$SettingName' on $ResourceFriendlyName..."

    Set-AzDiagnosticSetting `
        -Name        $SettingName `
        -ResourceId  $ResourceId `
        -WorkspaceId $Workspace.ResourceId `
        -Enabled     $true `
        -CategoryGroup "AllLogs","AllMetrics" `
        | Out-Null

    Write-Host "Diagnostic setting '$SettingName' created on $ResourceFriendlyName."
}

# --------------------------------------------------------------------
# Key Vault → Log Analytics
# --------------------------------------------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Ensure-DiagnosticSetting `
        -ResourceId           $keyVault.ResourceId `
        -SettingName          "diag-$($keyVaultName)" `
        -Workspace            $workspace `
        -ResourceFriendlyName "Key Vault '$keyVaultName'"
}
else {
    Write-Warning "Key Vault '$keyVaultName' not found in resource group '$rgName'. Skipping KV diagnostics."
}

# --------------------------------------------------------------------
# Storage Account (tag-based discovery) → Log Analytics
# --------------------------------------------------------------------
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue

$storage = $storageAccounts |
    Where-Object {
        $_.Tags["app"]         -eq $App       -and
        $_.Tags["environment"] -eq $Environment
    } |
    Select-Object -First 1

if ($storage) {
    Ensure-DiagnosticSetting `
        -ResourceId           $storage.Id `
        -SettingName          "diag-$($storage.StorageAccountName)" `
        -Workspace            $workspace `
        -ResourceFriendlyName "Storage account '$($storage.StorageAccountName)'"
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
