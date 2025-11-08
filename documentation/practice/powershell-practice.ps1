# powershell-practice.ps1
# Used for muscle-memory practice & experimentation

# Inspecting objects
Get-Service | Get-Member

# Pipeline transformation
Get-Process |
  Where-Object { $_.CPU -gt 1 } |
  Select Name, CPU |
  Sort-Object CPU -Descending

# Arrays
$names = @("one","two","three")
$names[0]
$names[1]

# Hashtables
$tags = @{ env="dev"; app="core"; owner="lucian" }
$tags.env
$tags.app

# Idempotent pattern (RG example logic, no creation here)
$rgName = "rg-test"
$location = "westeurope"
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if ($rg) { "RG exists" } else { "RG does not exist" }
