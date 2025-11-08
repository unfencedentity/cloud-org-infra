# PowerShell Modules (Cloud Automation)

This directory contains reusable PowerShell modules used across cloud automation scripts.

Modules allow us to:
- Reuse logic across multiple scripts
- Keep automation clean, predictable, and maintainable
- Enforce naming and tagging standards
- Support idempotent deployments (safe to run multiple times)

## Current Modules

| Module     | Description                                        |
|------------|----------------------------------------------------|
| az-core.psm1 | Core utility functions (idempotent RG creation)  |

## How to use modules

```powershell
# Import the module
Import-Module ./modules/az-core.psm1 -Force

# Call the function (example)
New-CoreResourceGroup -Name "rg-app-dev-weu" -Location "westeurope" -Tags @{ env="dev"; app="core" }

Module design principles

Keep modules small and focused on a single purpose

Avoid hard-coded values (always use parameters)

Ensure idempotency (safe repeatable deployments)

Follow Verb-Noun naming conventions

Functions should return objects, not plain text
