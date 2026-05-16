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

$resourceGroupName = "rg-$Environment-$App-$Region"
$vmName            = "vm-$Environment-$App-$Region-01"

Write-Host "Starting VM deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "VM Name: $vmName"
Write-Host "Location: $Location"

Write-Host "VM deployment placeholder completed."