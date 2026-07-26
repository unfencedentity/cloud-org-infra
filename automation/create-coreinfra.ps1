<#
.SYNOPSIS
  Creates core infrastructure components for the organization.

.DESCRIPTION
  This script loads the CoreInfrastructure PowerShell module and ensures
  that the required resource group and storage account exist. It is the
  main entrypoint for provisioning the base infrastructure and will be
  used by GitHub Actions (OIDC-based CI/CD).

#>

param(
    [string]$Environment = "dev",
  [string]$Region,
  [string]$Location,
    [string]$Owner     = "lucian"
)

. "$PSScriptRoot\shared\DeploymentDefaults.ps1"

$deploymentContext = Resolve-DeploymentRegionLocation -Region $Region -Location $Location
$Region = $deploymentContext.Region
$Location = $deploymentContext.Location

# Compute names
$rgName = "rg-$Environment-$Region"
$storageName = "st$($Environment)$($Region)2401"
$tags = @{
    owner = $Owner
    env   = $Environment
    app   = "core"
}

Write-Host "=== Loading CoreInfrastructure module ===" -ForegroundColor Cyan

$modulePath = Join-Path $PSScriptRoot "modules/CoreInfrastructure/CoreInfrastructure.psm1"
Import-Module $modulePath -Force

Write-Host "=== Ensuring Resource Group ===" -ForegroundColor Cyan
Ensure-ResourceGroup -Name $rgName -Location $Location -Tags $tags

Write-Host "=== Ensuring ADLS Gen2 Storage Account ===" -ForegroundColor Cyan
Ensure-StorageAccount -Name $storageName -ResourceGroupName $rgName -Location $Location -Tags $tags

Write-Host "`n=== Core infrastructure deployment complete ===" -ForegroundColor Green
