# File: automation/create-rbac.ps1

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Optional lists of AAD object IDs (users, groups, service principals)
    [Parameter(Mandatory = $false)][string[]]$ReaderObjectIds              = @(),
    [Parameter(Mandatory = $false)][string[]]$ContributorObjectIds         = @(),
    [Parameter(Mandatory = $false)][string[]]$KeyVaultSecretsUserObjectIds = @()
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------
# Naming & scope
# --------------------------------------------------------------------
$rgName = "rg-$App-$Environment-$Region"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

$scope = $rg.ResourceId
Write-Host "Using scope '$scope' for RBAC assignments."

# --------------------------------------------------------------------
# Role definitions
# --------------------------------------------------------------------
$readerRole = Get-AzRoleDefinition -Name "Reader" -ErrorAction Stop
$contributorRole = Get-AzRoleDefinition -Name "Contributor" -ErrorAction Stop
$keyVaultSecretsUserRole = Get-AzRoleDefinition -Name "Key Vault Secrets User" -ErrorAction SilentlyContinue

if (-not $keyVaultSecretsUserRole) {
    Write-Warning "Role 'Key Vault Secrets User' not found in this environment. KV-specific assignments will be skipped."
}

# --------------------------------------------------------------------
# Helper: ensure a single role assignment
# --------------------------------------------------------------------
function Ensure-RoleAssignment {
    param(
        [Parameter(Mandatory = $true)][string]$ObjectId,
        [Parameter(Mandatory = $true)][string]$RoleName,
        [Parameter(Mandatory = $true)][string]$RoleDefinitionId,
        [Parameter(Mandatory = $true)][string]$Scope
    )

    $existing = Get-AzRoleAssignment `
        -ObjectId $ObjectId `
        -RoleDefinitionName $RoleName `
        -Scope $Scope `
        -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Host ("Role '{0}' already assigned on scope '{1}' for object '{2}'." -f $RoleName, $Scope, $ObjectId)
        return $existing
    }

    if ($PSCmdlet.ShouldProcess(("ObjectId {0}" -f $ObjectId), ("Assign role {0} on {1}" -f $RoleName, $Scope))) {
        Write-Host ("Assigning role '{0}' on scope '{1}' for object '{2}'..." -f $RoleName, $Scope, $ObjectId)

        $assignment = New-AzRoleAssignment `
            -ObjectId $ObjectId `
            -RoleDefinitionId $RoleDefinitionId `
            -Scope $Scope `
            -ErrorAction Stop

        Write-Host ("Role '{0}' assigned on scope '{1}' for object '{2}'." -f $RoleName, $Scope, $ObjectId)
        return $assignment
    }
}

# --------------------------------------------------------------------
# Reader assignments
# --------------------------------------------------------------------
if ($ReaderObjectIds.Count -gt 0) {
    Write-Host "Processing Reader assignments..."
    foreach ($id in $ReaderObjectIds) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        Ensure-RoleAssignment `
            -ObjectId $id `
            -RoleName "Reader" `
            -RoleDefinitionId $readerRole.Id `
            -Scope $scope | Out-Null
    }
}
else {
    Write-Host "No ReaderObjectIds provided. Skipping Reader role assignments."
}

# --------------------------------------------------------------------
# Contributor assignments
# --------------------------------------------------------------------
if ($ContributorObjectIds.Count -gt 0) {
    Write-Host "Processing Contributor assignments..."
    foreach ($id in $ContributorObjectIds) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        Ensure-RoleAssignment `
            -ObjectId $id `
            -RoleName "Contributor" `
            -RoleDefinitionId $contributorRole.Id `
            -Scope $scope | Out-Null
    }
}
else {
    Write-Host "No ContributorObjectIds provided. Skipping Contributor role assignments."
}

# --------------------------------------------------------------------
# Key Vault Secrets User assignments
# --------------------------------------------------------------------
if ($KeyVaultSecretsUserObjectIds.Count -gt 0 -and $keyVaultSecretsUserRole) {
    Write-Host "Processing Key Vault Secrets User assignments..."
    foreach ($id in $KeyVaultSecretsUserObjectIds) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        Ensure-RoleAssignment `
            -ObjectId $id `
            -RoleName "Key Vault Secrets User" `
            -RoleDefinitionId $keyVaultSecretsUserRole.Id `
            -Scope $scope | Out-Null
    }
}
elseif ($KeyVaultSecretsUserObjectIds.Count -gt 0 -and -not $keyVaultSecretsUserRole) {
    Write-Warning "KeyVaultSecretsUserObjectIds provided but the role 'Key Vault Secrets User' is not available in this environment."
}
else {
    Write-Host "No KeyVaultSecretsUserObjectIds provided. Skipping Key Vault Secrets User assignments."
}

Write-Host "RBAC configuration completed for Resource Group '$rgName' (scope '$scope')."

return Get-AzRoleAssignment -Scope $scope -ErrorAction SilentlyContinue
