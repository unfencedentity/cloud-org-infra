# create-policy.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Environment,

    [Parameter(Mandatory)]
    [string]$App,

    [Parameter(Mandatory)]
    [string]$Region
)

Set-StrictMode -Version Latest

Import-Module "$PSScriptRoot\modules\AzurePolicy\AzurePolicy.psm1" -Force

Write-Host "Starting Azure Policy deployment..."

$resourceGroupName = "rg-$App-$Environment-$Region"

$scope = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$resourceGroupName"

Ensure-PolicyAssignment `
    -AssignmentName "RequireEnvironmentTag" `
    -PolicyDefinitionName "Require a tag on resources" `
    -Scope $scope `
    -PolicyParameters @{
        tagName = "environment"
    }

Write-Host "Azure Policy deployment completed."
