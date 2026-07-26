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

. "$PSScriptRoot\shared\DeploymentNaming.ps1"
. "$PSScriptRoot\shared\ObjectShape.ps1"

$names = Get-DeploymentNames -Environment $Environment -App $App -Region $Region

$resourceGroupName = $names.ResourceGroupName
$managedIdentityName = $names.ManagedIdentityName
$appServicePlanName = $names.AppServicePlanName
$webAppName = $names.WebAppName

Write-Host "Starting Managed Identity deployment..."
Write-Host "Resource Group       : $resourceGroupName"
Write-Host "Managed Identity     : $managedIdentityName"
Write-Host "App Service Plan     : $appServicePlanName"
Write-Host "Location             : $Location"

$provider = Get-AzResourceProvider `
    -ProviderNamespace Microsoft.ManagedIdentity

if ($provider.RegistrationState -ne "Registered") {
    Register-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity | Out-Null

    $attempt = 0
    do {
        Start-Sleep -Seconds 5
        $provider = Get-AzResourceProvider -ProviderNamespace Microsoft.ManagedIdentity
        $attempt++
    }
    while ($provider.RegistrationState -ne "Registered" -and $attempt -lt 24)

    if ($provider.RegistrationState -ne "Registered") {
        throw "Microsoft.ManagedIdentity provider is not registered. Current state: '$($provider.RegistrationState)'."
    }
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
    -Name $webAppName `
    -ErrorAction SilentlyContinue

if (-not $appService) {
    Write-Warning "Web App '$webAppName' not found. Skipping identity assignment."
    return $identity
}

Write-Host "App Service found: $($appService.Name)"

$existingUserAssignedIdentities = @{}
$hasIdentity = Test-ObjectProperty -Object $appService -PropertyName "Identity"

if ($hasIdentity -and $appService.Identity) {
    $hasUserAssignedIdentities = Test-ObjectProperty -Object $appService.Identity -PropertyName "UserAssignedIdentities"
    if ($hasUserAssignedIdentities -and $appService.Identity.UserAssignedIdentities) {
        $existingUserAssignedIdentities = $appService.Identity.UserAssignedIdentities
    }
}

$identityAlreadyAssigned = $false

if ($existingUserAssignedIdentities -and $identity -and $identity.Id) {
    foreach ($assignedIdentityId in $existingUserAssignedIdentities.Keys) {
        if ($assignedIdentityId -eq $identity.Id) {
            $identityAlreadyAssigned = $true
            break
        }
    }
}

if ($identityAlreadyAssigned) {
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
    }

    $updatedAppService = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ErrorAction SilentlyContinue

    $updatedAssignedIdentities = @{}
    if ($updatedAppService -and (Test-ObjectProperty -Object $updatedAppService -PropertyName "Identity") -and $updatedAppService.Identity) {
        if (Test-ObjectProperty -Object $updatedAppService.Identity -PropertyName "UserAssignedIdentities") {
            $updatedAssignedIdentities = Get-ObjectPropertyValue -Object $updatedAppService.Identity -PropertyName "UserAssignedIdentities" -DefaultValue @{}
        }
    }

    $isNowAssigned = $false
    if ($updatedAssignedIdentities -and $identity -and $identity.Id) {
        foreach ($assignedIdentityId in $updatedAssignedIdentities.Keys) {
            if ($assignedIdentityId -eq $identity.Id) {
                $isNowAssigned = $true
                break
            }
        }
    }

    if (-not $isNowAssigned) {
        throw "Managed Identity assignment command completed but identity '$($identity.Id)' is not present on web app '$webAppName'."
    }

    Write-Host "Managed Identity assigned to App Service successfully."
}

return $identity
