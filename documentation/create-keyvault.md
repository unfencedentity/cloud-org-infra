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

---

## Validation

The implementation was validated by:

* Creating an Azure Key Vault
* Verifying vault deployment
* Verifying HTTPS access
* Verifying RBAC configuration
* Creating and retrieving test secrets
* Executing repeated deployments to confirm idempotency

---

## AZ-104 Topics

* Azure Key Vault
* Secrets
* Keys
* Certificates
* Azure RBAC
* Access Control
* Encryption
* Managed Identity

---

## Common Interview Topics

* What is Azure Key Vault?
* Secrets vs Keys vs Certificates
* Key Vault RBAC vs Access Policies
* Why store secrets in Key Vault?
* Managed Identity integration
* Application secret management

---

## Common Mistakes

* Storing secrets directly in code
* Using hardcoded credentials
* Excessive permissions on vault resources
* Not using Managed Identities
* Poor secret rotation practices

---

## Simple Analogy

A Key Vault is like a highly secure company safe. Instead of storing passwords and certificates inside applications, they are stored centrally and accessed only by authorized identities.

---

## Key Takeaways

* Azure Key Vault centralizes secret management.
* Secrets, keys, and certificates are protected through controlled access.
* Managed Identities eliminate the need for hardcoded credentials.
* Key Vault improves security, governance, and operational reliability.

