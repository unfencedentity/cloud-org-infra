# Networking Design (Draft)

## VNet
- Address space: 10.20.0.0/16

## Subnets
- subnet-core-services: 10.20.1.0/24
- subnet-apps: 10.20.2.0/24
- subnet-data: 10.20.3.0/24

## Design principles
- Segmentation by function (core, apps, data)
- Least privilege network access
- Private communication preferred (Private Endpoints)

## Next steps
- Define NSG rules per subnet
- Add Private Endpoint strategy
- Integrate with Private DNS Zones