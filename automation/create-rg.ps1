param(
    [Parameter(Mandatory=$true)][string]$Environment,
    [Parameter(Mandatory=$true)][string]$App,
    [Parameter(Mandatory=$true)][string]$Region,
    [Parameter(Mandatory=$true)][string]$Location
)

$ErrorActionPreference = 'Stop'

# Derive RG name (adjust if you have a different naming convention)
$resourceGroupName = "$($App)-$($Environment)-rg-$($Region)"

# Optional tags
$tags = @{
    "environment" = $Environment
    "app"         = $App
    "region"      = $Region
    "owner"       = "cloud-org-infra"
}

$existing = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "ℹ Resource group '$resourceGroupName' already exists in '$($existing.Location)'. Skipping create."
} else {
    Write-Host "🆕 Creating resource group '$resourceGroupName' in '$Location'..."
    New-AzResourceGroup -Name $resourceGroupName -Location $Location -Tag $tags | Out-Null
    Write-Host "✔ Resource group '$resourceGroupName' created."
}
