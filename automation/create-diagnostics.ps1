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
# Naming
# --------------------------------------------------------------------
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

Write-Host "Configuring diagnostics for '$App' ($Environment/$Region)..."

# --------------------------------------------------------------------
# Resource Group
# --------------------------------------------------------------------
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "Resource group '$rgName' does not exist." }

# --------------------------------------------------------------------
# Log Analytics Workspace
# --------------------------------------------------------------------
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) {
    throw "Workspace '$workspaceName' not found in '$rgName'."
}

Write-Host "Using workspace '$($workspace.Name)' ($($workspace.ResourceId))"

# --------------------------------------------------------------------
# Helper: Create Diagnostic Setting
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
        Write-Host "Diagnostic setting '$SettingName' already exists on $ResourceFriendlyName."
        return
    }

    Write-Host "Creating diagnostic setting '$SettingName' on $ResourceFriendlyName..."

    # Category fallback (runner does not support CategoryGroup)
    $categories = @("AuditEvent", "Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth")

    $params = @{
        Name        = $SettingName
        ResourceId  = $ResourceId
        WorkspaceId = $Workspace.ResourceId
        Enabled     = $true
    }

    # Check available command
    if (Get-Command -Name Set-AzDiagnosticSetting -ErrorAction SilentlyContinue) {

        # Set individually
        foreach ($cat in $categories) {
            try {
                Set-AzDiagnosticSetting @params -Category $cat -ErrorAction SilentlyContinue | Out-Null
            } catch { }
        }
    }
    elseif (Get-Command -Name New-AzDiagnosticSetting -ErrorAction SilentlyContinue) {

        # Create with categories list
        New-AzDiagnosticSetting @params -Category $categories | Out-Null
    }
    else {
        throw "No diagnostic cmdlets available (Set-AzDiagnosticSetting / New-AzDiagnosticSetting missing)."
    }

    Write-Host "Diagnostics applied for $ResourceFriendlyName."
}

# --------------------------------------------------------------------
# Key Vault Diagnostics
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
    Write-Warning "Key Vault '$keyVaultName' not found. Skipping."
}

# --------------------------------------------------------------------
# Storage Account (tag-based discovery)
# --------------------------------------------------------------------
$storage = Get-AzStorageAccount -ResourceGroupName $rgName -ErrorAction SilentlyContinue |
           Where-Object {
               $_.Tags["app"] -eq $App -and $_.Tags["environment"] -eq $Environment
           } |
           Select-Object -First 1

if ($storage) {
    Ensure-DiagnosticSetting `
        -ResourceId $storage.Id `
        -SettingName "diag-$($storage.StorageAccountName)" `
        -Workspace $workspace `
        -ResourceFriendlyName "Storage Account '$($storage.StorageAccountName)'"
}
else {
    Write-Warning "No matching storage account found. Skipping storage diagnostics."
}

Write-Host "Diagnostics configuration complete."

return @{
    Workspace     = $workspace
    KeyVaultName  = $keyVaultName
    ResourceGroup = $rgName
}
