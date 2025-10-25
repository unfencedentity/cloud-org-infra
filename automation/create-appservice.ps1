# create-appservice.ps1
# Creează un App Service Plan + Web App conform naming & tagging policies
# Ex: .\create-appservice.ps1 -Env dev -Region weu -AppName portal -Location westeurope

param(
    [ValidateSet("dev","test","prod")]
    [string]$Env = "dev",
    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region = "weu",
    [string]$AppName = "portal",
    [string]$Location = "westeurope",
    [string]$Sku = "B1",
    [string]$RgName
)

# ---------- Resource Group ----------
if (-not $RgName) { $RgName = "$Env-rg-$Region-$AppName" }

# ---------- Naming ----------
$planName = "$Env-asp-$Region-$AppName"
$webAppName = "$Env-app-$Region-$AppName"

# ---------- Taguri ----------
$tags = @{
    env        = $Env
    owner      = "lucian.s@cloudorg.local"
    costCenter = "CC1001"
    app        = "cloud-org-$AppName"
    dataClass  = "internal"
}

# ---------- Creează RG dacă nu există ----------
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location -Tag $tags | Out-Null
    Write-Host "✅ Created RG $RgName"
}

# ---------- Creează App Service Plan ----------
New-AzAppServicePlan `
  -Name $planName `
  -Location $Location `
  -ResourceGroupName $RgName `
  -Tier "Basic" `
  -NumberofWorkers 1 `
  -WorkerSize "Small" `
  -Tag $tags | Out-Null

Write-Host "✅ Created App Service Plan: $planName"

# ---------- Creează Web App ----------
New-AzWebApp `
  -Name $webAppName `
  -ResourceGroupName $RgName `
  -Location $Location `
  -AppServicePlan $planName `
  -Tag $tags | Out-Null

Write-Host "✅ Web App '$webAppName' created successfully in plan '$planName'"
