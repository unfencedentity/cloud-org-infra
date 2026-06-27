[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [Parameter(Mandatory = $true)]
    [string]$Location
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"
$managedIdentityName = "mi-$App-$Environment-$Region"

Write-Host "Starting Managed Identity deployment..."
Write-Host "Resource Group       : $resourceGroupName"
Write-Host "Managed Identity     : $managedIdentityName"
Write-Host "Location             : $Location"

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $resourceGroup) {
    throw "Resource group not found: $resourceGroupName"
}

$existingIdentity = Get-AzUserAssignedIdentity `
    -ResourceGroupName $resourceGroupName `
    -Name $managedIdentityName `
    -ErrorAction SilentlyContinue

if ($existingIdentity) {
    Write-Host "Managed Identity already exists: $managedIdentityName. Skipping creation."
    return $existingIdentity
}

if ($PSCmdlet.ShouldProcess($managedIdentityName, "Create User Assigned Managed Identity")) {
    Write-Host "Creating Managed Identity: $managedIdentityName"

    $identity = New-AzUserAssignedIdentity `
        -ResourceGroupName $resourceGroupName `
        -Name $managedIdentityName `
        -Location $Location

    Write-Host "Managed Identity created: $managedIdentityName"

    return $identity
}
