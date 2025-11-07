# PowerShell Function Structure (Professional Standard)

This guide defines the standard function pattern used in reusable infrastructure automation.

---

## 1) Function Naming

Use **Verb-Noun** with a clear, single purpose:

```
New-CoreResourceGroup
Set-StorageTagPolicy
Remove-AppAccess
```

Avoid vague names like `DoStuff`, `SetupEnv`, `Script.ps1`.

---

## 2) Professional Function Template

```powershell
function New-CoreResourceGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Location,
        [Parameter()][hashtable]$Tags
    )

    $existing = Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue

    if ($existing) {
        if ($Tags) { Set-AzResourceGroup -Name $Name -Tag $Tags | Out-Null }
        Write-Verbose "Resource Group exists: $Name"
        return $existing
    }

    $created = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags
    Write-Verbose "Resource Group created: $Name"
    return $created
}
```

---

## 3) Key Principles

| Principle | Why it matters |
|----------|----------------|
| **Idempotent** | Re-running does not create duplicates |
| **Small + focused** | Each function solves *one job* |
| **Returns objects, not console text** | Supports CI/CD automation & composition |
| **Clear parameters** | Reusable across environments (Dev/Test/Prod) |

---

## 4) Return Objects, Not Strings

❌ Bad:
```powershell
Write-Host "Created storage account!"
```

✅ Good:
```powershell
return $storageAccount
```

This allows chaining functions, pipelines, modules, and testing.

---

## 5) Where This Leads Next

These functions will be grouped into **PowerShell modules**:

```
/automation/modules/
  CoreInfrastructure/
    CoreInfrastructure.psm1
    CoreInfrastructure.psd1
```

Modules allow:

- Versioning
- Reuse across multiple environments
- Unit testing
- Integration into GitHub Actions pipelines

---

Status: Foundation complete — ready to move to **modules**.
