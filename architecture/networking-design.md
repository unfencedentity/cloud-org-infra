# Networking Design

## Current Topology

- Core VNet: vnet-core-dev-weu
- Core address space: 10.10.0.0/16
- Hub VNet: vnet-hub-dev-weu
- Hub address space: 10.20.0.0/16
- Hub subnet: subnet-hub-services
- Hub subnet prefix: 10.20.0.0/24

```text
vnet-core-dev-weu (10.10.0.0/16)
        |
        | VNet Peering (bidirectional)
        |
vnet-hub-dev-weu (10.20.0.0/16)
  +-- subnet-hub-services (10.20.0.0/24)
```

## Peering Design

Directional peerings:

- peer-core-to-hub
- peer-hub-to-core

Validated configuration for both:

- AllowVirtualNetworkAccess = true
- AllowForwardedTraffic = false
- AllowGatewayTransit = false
- UseRemoteGateways = false

Rationale:

- Forwarded traffic remains disabled until transit controls are intentionally introduced (Azure Firewall, NVA, VPN Gateway, or Route Server).
- Gateway transit and remote gateways remain disabled because there is no shared transit gateway pattern in the current design.

## Routing Behavior

With connected peering, Azure injects remote VNet prefixes into effective routes automatically.

Expected next hop for remote VNet prefixes:

- Next Hop Type = VNet peering

## Design Principles

- Deterministic naming and address planning
- Non-overlapping VNet CIDR ranges
- Idempotent network automation
- Explicit validation and fail-fast on configuration drift
- Secure-by-default peering configuration