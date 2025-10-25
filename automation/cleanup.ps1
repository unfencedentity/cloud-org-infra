# cleanup.ps1
# Șterge resursele pentru o aplicație într-un environment (RG + conținut)
# Ex: .\cleanup.ps1 -Env dev -Region weu -AppName core -Location westeurope -Force

param(
    [ValidateSet("dev","test","prod")]
    [string]$Env = "dev",
    [ValidateSet("weu","neu","eus","wus")]
    [string]$Region = "weu",
    [string]$AppName = "core",
    [string]$Location = "westeurope",
    [switch]$Force
)

$rgName = "$Env-rg-$Region-$AppName"

Write-Host "⚠️  Cleanup will remove Resource Group '$rgName' and all resources in $Location"

if (-not $Force) {
    $answer = Read-Host "Type 'YES' to confirm"
    if ($answer -ne "YES") {
        Write-Host "Cancelled."
        exit 0
    }
}

if (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue) {
    Remove-AzResourceGroup -Name $rgName -Force -AsJob
    Write-Host "🧹 Deletion started for RG '$rgName' (running as background job)."
} else {
    Write-Host "ℹ️  Resource Group '$rgName' not found."
}
