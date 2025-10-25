# create-rg.ps1
# Script PowerShell pentru crearea unui Resource Group în Azure cu naming și tagging corect

param(
    [string]$Env = "dev",
    [string]$Svc = "rg",
    [string]$Region = "weu",
    [string]$Name = "core",
    [string]$Location = "westeurope"
)

# Creează denumirea completă conform convenției
$resourceGroupName = "$Env-$Svc-$Region-$Name"

# Creează dicționarul de taguri
$tags = @{
    env        = $Env
    owner      = "lucian.s@cloudorg.local"
    costCenter = "CC1001"
    app        = "cloud-org-core"
    dataClass  = "internal"
}

# Creează Resource Group-ul
New-AzResourceGroup -Name $resourceGroupName -Location $Location -Tag $tags

Write-Host "Resource Group '$resourceGroupName' created successfully in $Location"
