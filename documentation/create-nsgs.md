# NSG Module (create-nsgs.ps1)

This module provisions a Network Security Group (NSG) and optionally associates it with one or more subnets in a previously created virtual network. It follows the same naming and tagging conventions as the rest of the cloud-org-infra automation.

---

## Features

- Creates a Network Security Group in an existing resource group
- Standardized naming convention for the NSG
- Default inbound rules for HTTP/HTTPS traffic
- Built-in tagging aligned with the project (environment, app, region, owner)
- Idempotent behavior (create or reuse if the NSG already exists)
- Optional association of the NSG with selected subnets in the VNet
- Returns the NSG object for further use by other modules

---

## Naming Convention

The module expects the following naming patterns:

Resource group:

rg-<app>-<environment>-<region>

Example:

rg-core-dev-weu

Virtual network:

vnet-<app>-<environment>-<region>

Example:

vnet-core-dev-weu

Network Security Group:

nsg-<app>-<environment>-<region>

Example:

nsg-core-dev-weu

---

## Parameters

Name | Type | Required | Description
-----|------|----------|------------
Environment | string | Yes | Deployment environment (dev, test, prod, etc.)
App | string | Yes | Application identifier
Region | string | Yes | Region short-code (weu, neu, eus, etc.)
Location | string | Yes | Azure location (westeurope, northeurope, etc.)
VirtualNetworkName | string | No | Optional override for the VNet name; defaults to vnet-<app>-<environment>-<region>
SubnetsToAssociate | string[] | No | List of subnet names to associate with the NSG (defaults: subnet-core, subnet-app)

---

## Default Tags

The module applies the following default tags to the NSG:

environment = <Environment>  
app         = <App>  
region      = <Region>  
owner       = cloud-org-infra  

These tags help with governance, cost allocation and environment tracking.

---

## Default Rules

The module creates a basic set of inbound rules intended for a typical web workload:

- allow-http-in  
  - TCP 80  
  - Direction: Inbound  
  - Source: *  
  - Destination: *  

- allow-https-in  
  - TCP 443  
  - Direction: Inbound  
  - Source: *  
  - Destination: *  

These are examples and can be extended or modified in a customized version of the module.

---

## Usage Examples

### Basic execution with default VNet name and default subnets

    .\create-nsgs.ps1 -Environment dev -App core -Region weu -Location westeurope

### Associate NSG only with a specific subset of subnets

    .\create-nsgs.ps1 `
      -Environment dev `
      -App core `
      -Region weu `
      -Location westeurope `
      -SubnetsToAssociate @("subnet-core")

### Use a custom VNet name

    .\create-nsgs.ps1 `
      -Environment dev `
      -App core `
      -Region weu `
      -Location westeurope `
      -VirtualNetworkName "vnet-custom-dev-weu" `
      -SubnetsToAssociate @("subnet-core", "subnet-app")

---

## Idempotency Behavior

The module first checks for an existing NSG with the expected name in the target resource group:

- If the NSG already exists, it is reused and no new NSG is created.
- If the NSG does not exist, a new NSG is created with the defined rules and tags.

For subnet associations:

- If a subnet is already associated with the NSG, the association is left unchanged.
- If a subnet is not associated with the NSG, the association is created.
- If a subnet listed in SubnetsToAssociate does not exist in the VNet, a warning is logged and the subnet is skipped.

---

## Return Value

The module returns the Network Security Group object:

- Existing NSG if it was already present.
- Newly created NSG if it did not exist.

This NSG object can be consumed by other modules or orchestration layers, for example when creating application gateways, load balancers, or additional subnet associations.
