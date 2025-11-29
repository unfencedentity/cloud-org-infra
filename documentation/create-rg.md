=== BEGIN create-rg.md ===
# Resource Group Module (create-rg.ps1)

This module creates or validates an Azure Resource Group based on standardized naming conventions and tagging policies. It is designed for idempotent infrastructure automation and can be safely executed multiple times.

---

## Features

- Standardized naming convention  
- Idempotent execution (create or skip)  
- Built-in tagging structure  
- Supports additional custom tags  
- Returns the existing or newly created Resource Group object  
- Supports -WhatIf and -Confirm via ShouldProcess

---

## Naming Convention

Resource Group names follow the pattern:

rg-<app>-<environment>-<region>

Example:

rg-core-dev-weu

---

## Parameters

Name | Type | Required | Description
-----|------|----------|-------------
Environment | string | Yes | Deployment environment (dev, test, prod)
App | string | Yes | Application identifier
Region | string | Yes | Region short-code (weu, neu, eus)
Location | string | Yes | Azure location name (westeurope, northeurope)
AdditionalTags | hashtable | No | Optional additional tags

---

## Default Tags

The module applies the following default tags:

environment = <Environment>  
app         = <App>  
region      = <Region>  
owner       = cloud-org-infra  

Additional tags supplied via AdditionalTags override or extend this set.

---

## Usage Examples

### Basic execution

.\create-rg.ps1 -Environment dev -App core -Region weu -Location westeurope

### With additional tags

.\create-rg.ps1 -Environment dev -App core -Region weu -Location westeurope -AdditionalTags @{ costCenter = "CC1001"; project = "Migration" }

---

## Idempotency Behavior

The module checks for an existing Resource Group:

- If the RG already exists, the module logs a message and returns the existing object.
- If the RG does not exist, a new Resource Group is created with the standard tagging policy.

---

## Return Value

The module returns the Resource Group object:

- Existing RG if already present
- Newly created RG if not

This allows other deployment modules or orchestration layers to consume the returned object.
=== END create-rg.md ===
