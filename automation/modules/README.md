# PowerShell Modules (Cloud Automation)

This directory contains reusable PowerShell modules used across the cloud automation scripts.

Modules allow us to:
- Reuse logic across multiple scripts
- Keep automation clean, predictable, and maintainable
- Enforce naming and tagging standards
- Support idempotent deployments (safe to run multiple times)

---

## Current Modules

| Module        | Description |
|---------------|-------------|
| az-core.psm1  | Core utility functions (idempotent resource group creation) |

---

## How to use modules

### 1) Import module
```powershell
Import-Module ./modules/az-core.psm1 -Force
