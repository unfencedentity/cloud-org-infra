# PowerShell Functions (Cloud Automation)

PowerShell functions allow us to create **reusable, predictable and idempotent** automation logic for Azure.  
This is how we avoid duplicate resources, ensure consistent naming and support CI/CD workflows.

---

## Why we use functions in cloud automation

Functions help us:

- Reuse logic across multiple scripts
- Keep automation code modular and maintainable
- Follow consistent naming rules (Verb-Noun)
- Implement **idempotency** (safe repeat deployments)
- Support multi-environment deployments (dev / stage / prod)

---

## Professional Function Pattern

This is the standardized structure we use:

```powershell
function New-CoreResourceGroup {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Location,
    [Parameter()][hashtable]$Tags
  )

  # Check if RG already exists (idempotent)
  $existing = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

  if ($existing) {
    if ($Tags) {
      Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null
    }
    Write-Host "RG exists: $Name"
    return $existing
  }

  # Create new RG
  $result = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
  Write-Host "RG created: $Name"
  return $result
}
