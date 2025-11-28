[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    # Optional: allows extending the default tag set
    [Parameter(Mandatory = $false)][hashtable]$AdditionalTags
)

$ErrorActionPreference = 'Stop'

# Naming convention for the resource group
$resourceGroupName = "rg-$App-$Environment-$Region"

# Default tagging
$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

# Merge any additional tags into the default tag set
if ($AdditionalTags) {
    foreach ($key in $AdditionalTags.Keys) {
        $tags[$key] = $AdditionalTags[$key]
    }
}

# Check if the resource group already exists
$existing = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host ("Resource group '{0}' already exists in '{1}'. Skipping create." -f `
        $resourceGroupName, $existing.Location)
    return $existing
}

# Supports -WhatIf / -Confirm
if (-not $PSCmdlet.ShouldProcess("Resource group '$resourceGroupName' in '$Location'", "Create")) {
    return
}

Write-Host ("Creating resource group '{0}' in '{1}'..." -f $resourceGroupName, $Location)

$rg = New-AzResourceGroup -Name $resourceGroupName -Location $Location -Tag $tags

Write-Host ("Resource group '{0}' created." -f $resourceGroupName)

return $rg
