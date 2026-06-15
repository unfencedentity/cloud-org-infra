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

---

## Validation

The implementation was validated by:

* Creating a Storage Account
* Verifying StorageV2 deployment
* Verifying HTTPS-only access
* Verifying tag assignment
* Confirming LRS redundancy configuration
* Executing repeated deployments to confirm idempotency

---

## Architecture

Applications
↓
Storage Account
↓
Blob Containers
↓
Files / Objects

---

## AZ-104 Topics

* Storage Accounts
* StorageV2
* Blob Storage
* Azure Files
* Redundancy Options
* LRS
* GRS
* ZRS
* Secure Transfer Required
* Storage Security

---

## Common Interview Topics

* What is a Storage Account?
* StorageV2 vs Classic Storage
* LRS vs GRS vs ZRS
* Blob Storage vs Azure Files
* Secure Transfer Required
* Storage account naming restrictions

---

## Common Mistakes

* Using incorrect redundancy options
* Disabling HTTPS access
* Poor naming conventions
* Not planning for growth and scalability
* Storing sensitive data without proper access controls

---

## Simple Analogy

A Storage Account is like a secure warehouse. Inside the warehouse, different storage areas can hold files, backups, logs, and application data.

---

## Key Takeaways

* Storage Accounts are the foundation of Azure storage services.
* StorageV2 provides access to modern Azure storage capabilities.
* Redundancy options determine data durability and availability.
* Secure storage design is critical for enterprise workloads.

