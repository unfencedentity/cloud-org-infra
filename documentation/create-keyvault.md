# Key Vault Module (create-keyvault.ps1)

This module creates or validates an Azure Key Vault using standardized naming, access, and tagging conventions. It is designed to be idempotent and safe to run multiple times.

---

## Purpose

- Ensure a Key Vault exists for a given app and environment
- Apply consistent naming and tagging
- Configure basic access policies or RBAC (depending on implementation)
- Return the existing or newly created Key Vault object

---

## Naming Convention

Key Vault names follow the pattern:

kv-<app>-<environment>-<region>

Example:

kv-core-dev-weu

The Key Vault is created in the resource group:

rg-<app>-<environment>-<region>

Example:

rg-core-dev-weu

---

## Parameters

Name | Type | Required | Description
-----|------|----------|-------------
Environment | string | Yes | Deployment environment (dev, test, prod, etc.)
App | string | Yes | Application identifier
Region | string | Yes | Region short-code (weu, neu, eus, etc.)
Location | string | Yes | Azure location (westeurope, northeurope, etc.)
AdditionalTags | hashtable | No | Optional additional tags merged into the default tag set

---

## Default Tags

The module applies the following base tags:

environment = <Environment>  
app         = <App>  
region      = <Region>  
owner       = cloud-org-infra  

Custom tags supplied through AdditionalTags extend or override this set.

---

## Usage Example

.\create-keyvault.ps1 -Environment dev -App core -Region weu -Location westeurope

---

## Idempotency

- If the Key Vault already exists, the module logs a message and returns the existing vault.
- If the Key Vault does not exist, it is created with the defined naming, tagging and configuration.

---

## Return Value

The module returns the Key Vault object, which can be consumed by other modules (for secrets, certificates, private endpoints, etc.).
