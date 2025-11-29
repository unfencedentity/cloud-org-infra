# Storage Module (create-storage.ps1)

This module provisions an Azure Storage Account with a standardized naming convention and tagging policy.  
It is idempotent: if the storage account already exists, the module returns the existing resource.

---

## Naming Convention
sa<app><environment><region>  
Example: sa core dev weu → sacoredevweu (lowercase enforced by Azure)

---

## Default Features
- Standardized naming
- StorageV2 type
- LRS redundancy
- HTTPS enforced
- Tagging aligned with the project

---

## Usage
.\create-storage.ps1 -Environment dev -App core -Region weu -Location westeurope
