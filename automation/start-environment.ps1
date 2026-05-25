param(
    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$Region
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"
$vmName = "vm-$App-$Environment-$Region-01"
$webAppNamePrefix = "app-$App-$Environment-$Region"

Write-Host "Starting environment resources..."
Write-Host "Resource Group: $resourceGroupName"

# Start VM
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue

if ($null -ne $vm) {
    Write-Host "Starting VM: $vmName"
    Start-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
}
else {
    Write-Host "VM not found: $vmName"
}

# Start App Services
$webApps = Get-AzWebApp -ResourceGroupName $resourceGroupName |
    Where-Object { $_.Name -like "$webAppNamePrefix*" }

if ($webApps.Count -gt 0) {
    foreach ($webApp in $webApps) {
        Write-Host "Starting App Service: $($webApp.Name)"
        Start-AzWebApp -ResourceGroupName $resourceGroupName -Name $webApp.Name
    }
}
else {
    Write-Host "No App Services found matching prefix: $webAppNamePrefix"
}

Write-Host "Environment start operation completed."
