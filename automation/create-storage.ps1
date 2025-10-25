# create-storage.ps1
# Creează un Storage Account conform naming & tagging. Necesită modulul Az.*
# Ex:  .\create-storage.ps1 -Env dev -Region weu -AppName core -Location westeurope

param(
    [ValidateSet("dev","test","prod")]
    [string]$Env = "dev",
    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region = "weu",
    [string]$AppName = "core",
    [string]$Location = "westeurope",
    [string]$SkuName = "Standard_LRS",
    [string]$Kind = "StorageV2",
    [string]$RgName # dacă nu e dat, îl construim
)

# ---------- Construcție nume RG (dacă nu e specificat) ----------
if (-not $RgName) {
    $RgName = "$Env-rg-$Region-$AppName"
}

# ---------- Taguri standard ----------
$tags = @{
    env        = $Env
    owner      = "lucian.s@cloudorg.local"
    costCenter = "CC1001"
    app        = "cloud-org-$AppName"
    dataClass  = "internal"
}

# ---------- Nume Storage Account (fără cratime, 3-24 chars, global unic) ----------
# pattern: st{env}{region}{app}{rand}
$rand   = -join ((48..57 + 97..122) | Get-Random -Count 3 | % {[char]$_})
$saName = ("st{0}{1}{2}{3}" -f $Env,$Region,$AppName,$rand).ToLower() -replace "[^a-z0-9]",""

# taie la max 24 caractere (politica Azure)
if ($saName.Length -gt 24) { $saName = $saName.Substring(0,24) }

Write-Host "➡ Resource Group: $RgName"
Write-Host "➡ Storage Account: $saName"

# ---------- Creează RG dacă nu există ----------
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location -Tag $tags | Out-Null
    Write-Host "✅ Created RG $RgName"
} else {
    Write-Host "ℹ RG $RgName already exists"
}

# ---------- Creează Storage Account ----------
New-AzStorageAccount `
  -Name $saName `
  -ResourceGroupName $RgName `
  -Location $Location `
  -SkuName $SkuName `
  -Kind $Kind `
  -EnableHttpsTrafficOnly $true `
  -Tag $tags | Out-Null

Write-Host "✅ Storage account $saName created in $Location (SKU: $SkuName)"
