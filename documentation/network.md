# Network Architecture and Modules

This document covers the network automation implemented by:

- create-network.ps1
- create-vnetpeering.ps1

The implementation is idempotent and validates existing resources before any create or update action.

---

## Validated Hub-and-Spoke Topology

Current validated topology:

- Core VNet: vnet-core-dev-weu
- Core address space: 10.10.0.0/16
- Hub VNet: vnet-hub-dev-weu
- Hub address space: 10.20.0.0/16
- Hub subnet: subnet-hub-services
- Hub subnet prefix: 10.20.0.0/24

Bidirectional peering:

- peer-core-to-hub
- peer-hub-to-core

```text
vnet-core-dev-weu (10.10.0.0/16)
        |
        | VNet Peering (bidirectional)
        |
vnet-hub-dev-weu (10.20.0.0/16)
  +-- subnet-hub-services (10.20.0.0/24)
```

---

## Module Responsibilities

create-network.ps1:

- Ensures Core VNet exists with expected address space and required subnets
- Ensures Hub VNet exists with expected address space
- Ensures Hub subnet exists with expected prefix
- Validates existing address spaces and subnet prefixes
- Fails fast on conflicting configuration

create-vnetpeering.ps1:

- Validates both VNets exist before peering operations
- Validates VNet address spaces do not overlap
- Creates or updates peer-core-to-hub and peer-hub-to-core
- Keeps peering settings aligned to the current validated configuration

---

## Naming and Addressing

Resource group:

- rg-<app>-<environment>-<region>

Core VNet:

- vnet-<app>-<environment>-<region>
- Default address space: 10.10.0.0/16

Hub VNet:

- vnet-hub-<environment>-<region>
- Default address space: 10.20.0.0/16

Hub subnet:

- subnet-hub-services
- Default prefix: 10.20.0.0/24

---

## Peering Configuration

Both directions are configured identically:

- AllowVirtualNetworkAccess: true
- AllowForwardedTraffic: false
- AllowGatewayTransit: false
- UseRemoteGateways: false

Reasoning:

- Forwarded traffic is disabled until centralized transit/routing controls exist (Azure Firewall, NVA, VPN Gateway, or Route Server).
- Gateway transit and remote gateways are disabled because the current architecture does not yet include a shared transit gateway design.

---

## Effective Routes Behavior

When VNet peering is connected, Azure automatically inserts routes for remote VNet prefixes into each NIC's effective routes.

Expected route behavior:

- Source NIC in Core sees Hub prefixes with Next Hop Type = VNet peering
- Source NIC in Hub sees Core prefixes with Next Hop Type = VNet peering

This route insertion is automatic and does not require a UDR for basic peered VNet connectivity.

---

## Idempotency and Validation Model

Network and peering modules are safe to re-run.

Behavior:

- Existing resources with matching configuration are reused unchanged
- Missing resources are created
- Existing peerings with drift are updated only for required properties
- Conflicting network configuration causes explicit script failure

Conflict examples that fail deployment:

- Existing Hub VNet has an address space that does not include 10.20.0.0/16
- Existing subnet-hub-services has a prefix other than 10.20.0.0/24
- Core and Hub VNet address spaces overlap

---

## Troubleshooting

1. Peering state

- Check both peerings and confirm PeeringState is Connected.
- If one side is Initiated, verify the opposite peering exists and targets the correct remote VNet.

2. Peering synchronization

- If properties differ across sides, rerun create-vnetpeering.ps1.
- Validate that each peering references the correct remote VNet resource ID.

3. Effective routes

- On a VM NIC, inspect effective routes.
- Confirm remote VNet prefixes appear with Next Hop Type = VNet peering.

4. NSGs

- Validate subnet and NIC NSG rules allow expected source/destination and port ranges.
- Remember that peering connectivity can still be blocked by NSG denies.

5. UDRs

- Check route tables associated to source and destination subnets.
- Ensure no UDR sends remote VNet prefixes to an unintended next hop.

6. Overlapping address spaces

- Validate that Core and Hub address spaces do not overlap.
- If overlap exists, peering creation or connectivity will fail and address planning must be corrected first.

