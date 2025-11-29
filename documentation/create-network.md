# Network Module (create-network.ps1)

This module provisions a virtual network (VNet) and a set of subnets based on standardized naming and addressing conventions. It is designed to be idempotent and can be safely executed multiple times.

---

## Features

- Creates a VNet in an existing resource group
- Creates one or more subnets from a configurable map
- Standardized naming convention for the VNet
- Built-in tagging aligned with the core project
- Idempotent behavior (create or skip if already exists)
- Returns the created or existing VNet object

---

## Naming Convention

The virtual network name follows the pattern:

vnet-<app>-<environment>-<region>

Example:

vnet-core-dev-weu

The resource group is expected to follow:

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
AddressPrefix | string | No | VNet address space (default: 10.10.0.0/16)
Subnets | hashtable | No | Map of subnet name to address prefix

---

## Default Addressing

By default, the module uses:

- VNet address space: 10.10.0.0/16  
- Subnets:
  - subnet-core : 10.10.1.0/24  
  - subnet-app  : 10.10.2.0/24  
  - subnet-data : 10.10.3.0/24  

These values can be overridden using the AddressPrefix and Subnets parameters.

---

## Usage Examples

### Basic execution

.\create-network.ps1 -Environment dev -App core -Region weu -Location westeurope

### Custom address space and subnets

.\create-network.ps1 `
  -Environment dev `
  -App core `
  -Region weu `
  -Location westeurope `
  -AddressPrefix "10.20.0.0/16" `
  -Subnets @{ `
      "subnet-core" = "10.20.1.0/24"; `
      "subnet-app"  = "10.20.2.0/24"; `
      "subnet-data" = "10.20.3.0/24" `
  }

---

## Idempotency Behavior

The module checks for an existing VNet in the target resource group:

- If the VNet already exists, the script logs a message and returns the existing VNet object.
- If the VNet does not exist, it is created with the specified address space, subnets, and tags.

---

## Return Value

The module returns the Azure virtual network object:

- Existing VNet if it was already present.
- Newly created VNet if it did not exist.

This allows other modules (for NSGs, application services, gateways, etc.) to consume the VNet configuration.
