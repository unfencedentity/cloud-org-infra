param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$VmSize = "Standard_B1s"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\DeploymentNaming.ps1"

$names = Get-DeploymentNames -Environment $Environment -App $App -Region $Region

$resourceGroupName = $names.ResourceGroupName
$vmName            = $names.VmName
$vnetName          = $names.CoreVNetName
$subnetName        = "subnet-app"
$adminUsername     = "azureuser"
$image             = "Ubuntu2204"

Write-Host "Starting VM deployment..."
Write-Host "Resource Group: $resourceGroupName"
Write-Host "VM Name: $vmName"
Write-Host "VNet: $vnetName"
Write-Host "Subnet: $subnetName"
Write-Host "Location: $Location"

Write-Host "Checking if Resource Group exists..."

$existingResourceGroup = az group show `
    --name $resourceGroupName `
    --query "name" `
    --output tsv 2>$null

if (-not $existingResourceGroup) {
    Write-Error "Resource Group not found: $resourceGroupName. VM deployment cannot continue."
    exit 1
}

Write-Host "Resource Group found: $existingResourceGroup"

Write-Host "Checking if VNet exists..."

$existingVnet = az network vnet show `
    --resource-group $resourceGroupName `
    --name $vnetName `
    --query "name" `
    --output tsv 2>$null

if (-not $existingVnet) {
    Write-Error "VNet not found: $vnetName. VM deployment cannot continue."
    exit 1
}

Write-Host "VNet found: $existingVnet"

Write-Host "Checking if subnet exists..."

$existingSubnet = az network vnet subnet show `
    --resource-group $resourceGroupName `
    --vnet-name $vnetName `
    --name $subnetName `
    --query "name" `
    --output tsv 2>$null

if (-not $existingSubnet) {
    Write-Error "Subnet not found: $subnetName. VM deployment cannot continue."
    exit 1
}

Write-Host "Subnet found: $existingSubnet"

Write-Host "Checking if VM already exists..."

$existingVm = az vm show `
    --resource-group $resourceGroupName `
    --name $vmName `
    --query "name" `
    --output tsv 2>$null

if ($existingVm) {
    Write-Host "VM already exists: $vmName. Skipping creation."
    return
}

Write-Host "VM does not exist. Creating VM..."

az vm create `
    --resource-group $resourceGroupName `
    --name $vmName `
    --image $image `
    --size $vmSize `
    --admin-username $adminUsername `
    --vnet-name $vnetName `
    --subnet $subnetName `
    --public-ip-address "" `
    --nsg "" `
    --generate-ssh-keys `
    --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Error "VM deployment failed."
    exit 1
}

Write-Host "VM deployment completed successfully."
