[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location
)

$ErrorActionPreference = "Stop"

Write-Host "Loading modules..."

Import-Module Az.Accounts
Import-Module Az.OperationalInsights
Import-Module Az.Resources

# Naming
$rgName        = "rg-$App-$Environment-$Region"
$workspaceName = "law-$App-$Environment-$Region"
$keyVaultName  = "kv-$App-$Environment-$Region"

# Validate RG
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) { throw "Resource group '$rgName' does not exist." }

# Workspace
$workspace = Get-AzOperationalInsightsWorkspace `
    -ResourceGroupName $rgName `
    -Name $workspaceName `
    -ErrorAction SilentlyContinue

if (-not $workspace) { throw "Workspace '$workspaceName' not found." }

$workspaceId = $workspace.ResourceId

Write-Host "Using workspace: $workspaceId"

# --------------------------------------------------------------------
# Helper: Create Diagnostic Setting Using REST API
# --------------------------------------------------------------------
function Set-DiagnosticSettingREST {
    param(
        [string]$ResourceId,
        [string]$SettingName,
        [string]$WorkspaceId
    )

    $url = "https://management.azure.com$ResourceId/providers/microsoft.insights/diagnosticSettings/$SettingName?api-version=2021-05-01-preview"

    $body = @{
        properties = @{
            workspaceId = $WorkspaceId
            logs = @(
                @{
                    category = "AuditEvent"
                    enabled  = $true
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

    $token = (Get-AzAccessToken).Token

    Write-Host "Sending REST diagnostic config for $ResourceId ..."

    $result = Invoke-RestMethod `
        -Method Put `
        -Uri $url `
        -Headers @{ Authorization = "Bearer $token" } `
        -Body $body `
        -ContentType "application/json"

    Write-Host "REST diagnostic setting applied: $SettingName"
}

# --------------------------------------------------------------------
# KV diagnostics
# --------------------------------------------------------------------
$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ErrorAction SilentlyContinue

if ($keyVault) {
    Set-DiagnosticSettingREST `
        -ResourceId $keyVault.ResourceId `
        -SettingName "diag-$keyVaultName" `
        -WorkspaceId $workspaceId
}
else {
    Write-Warning "Key Vault '$keyVaultName' not found. Skipping."
}

# --------------------------------------------------------------------
# Storage diagnostics
# --------------------------------------------------------------------
$storage = Get-AzResource -ResourceGroupName $rgName `
           | Where-Object { $_.ResourceType -eq "Microsoft.Storage/storageAccounts" } `
           | Where-Object {
               $_.Tags["app"] -eq $App -and $_.Tags["environment"] -eq $Environment
           } | Select-Object -First 1

if ($storage) {
    Set-DiagnosticSettingREST `
        -ResourceId $storage.ResourceId `
        -SettingName "diag-$($storage.Name)" `
        -WorkspaceId $workspaceId
}
else {
    Write-Warning "No storage account found for app '$App'. Skipping."
}

Write-Host "Diagnostics configuration complete."

return @{
    Workspace     = $workspace
    KeyVaultName  = $keyVaultName
    ResourceGroup = $rgName
}
