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
$appServicePlanName = "asp-$App-$Environment-$Region"

Write-Host "Starting Managed Identity deployment..."
Write-Host "Resource Group       : $resourceGroupName"
Write-Host "Managed Identity     : $managedIdentityName"
Write-Host "App Service Plan     : $appServicePlanName"
Write-Host "Location             : $Location"

$provider = Get-AzResourceProvider `
    -ProviderNamespace Microsoft.ManagedIdentity

if ($provider.RegistrationState -ne "Registered") {
    throw "Microsoft.ManagedIdentity provider is not registered."
}

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $resourceGroup) {
    throw "Resource group not found: $resourceGroupName"
}

$identity = Get-AzUserAssignedIdentity `
    -ResourceGroupName $resourceGroupName `
    -Name $managedIdentityName `
    -ErrorAction SilentlyContinue

if (-not $identity) {
    if ($PSCmdlet.ShouldProcess($managedIdentityName, "Create User Assigned Managed Identity")) {
        Write-Host "Creating Managed Identity: $managedIdentityName"

        $identity = New-AzUserAssignedIdentity `
            -ResourceGroupName $resourceGroupName `
            -Name $managedIdentityName `
            -Location $Location

        Write-Host "Managed Identity created: $managedIdentityName"
    }
}
else {
    Write-Host "Managed Identity already exists: $managedIdentityName. Skipping creation."
}

$appService = Get-AzWebApp `
    -ResourceGroupName $resourceGroupName `
    | Where-Object { $_.ServerFarmId -like "*$appServicePlanName*" } `
    | Select-Object -First 1

if (-not $appService) {
    Write-Warning "No App Service found in App Service Plan: $appServicePlanName. Skipping identity assignment."
    return $identity
}

Write-Host "App Service found: $($appService.Name)"

$existingUserAssignedIdentities = $appService.Identity.UserAssignedIdentities

if ($existingUserAssignedIdentities -and $existingUserAssignedIdentities.ContainsKey($identity.Id)) {
    Write-Host "Managed Identity already assigned to App Service: $($appService.Name)"
    return $identity
}

if ($PSCmdlet.ShouldProcess($appService.Name, "Assign User Assigned Managed Identity")) {
    Write-Host "Assigning Managed Identity '$managedIdentityName' to App Service '$($appService.Name)'"

    az webapp identity assign `
    --resource-group "$resourceGroupName" `
    --name "$($appService.Name)" `
    --identities "$($identity.Id)" | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "Failed to assign Managed Identity '$managedIdentityName' to App Service '$($appService.Name)'."

    Write-Host "Managed Identity assigned to App Service successfully."
}

return $identity
