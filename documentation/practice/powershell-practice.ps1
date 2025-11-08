# powershell-practice.ps1
# Hands-on practice for muscle memory (safe to run in Cloud Shell or local)

# --- Session context (read-only) ---
Get-AzContext | Select-Object Subscription, Account, Tenant

# --- Arrays & loop ---
$apps = @("sql","web","api","worker")
foreach ($app in $apps) { Write-Host "Component -> $app" }

# --- Hashtable (tags) ---
$tags = @{ env="dev"; app="core"; owner="lucian" }
$tags.env
$tags.app
$tags["owner"]

# --- Object inspection ---
Get-Process | Get-Member
Get-Service  | Select Name, Status | Sort-Object Status

# --- Idempotent Resource Group example ---
$rgName = "rg-test-weu"
$loc    = "westeurope"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

if ($rg) {
    Write-Host "RG exists:" $rg.ResourceGroupName
} else {
    Write-Host "Creating RG:" $rgName "in" $loc
    New-AzResourceGroup -Name $rgName -Location $loc | Out-Null
    Write-Host "RG created."
}

# --- Verify ---
Get-AzResourceGroup -Name $rgName | Select ResourceGroupName, Location, ProvisioningState

# --- Optional cleanup ---
# Remove-AzResourceGroup -Name $rgName -Force
