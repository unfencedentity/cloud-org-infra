# Private Endpoint

## Overview

This environment uses an Azure Private Endpoint to provide secure, private connectivity to the Storage Account Blob service.

Instead of accessing the Storage Account through its public endpoint, traffic remains entirely on the Microsoft backbone network by using a private IP address inside the Virtual Network.

This architecture follows enterprise security best practices by minimizing public exposure and preparing the environment for Zero Trust networking.

---

# Architecture

```
Virtual Machine / App Service
            │
            │
            ▼
    Virtual Network
            │
            ▼
     Private Endpoint
      (Private IP)
            │
            ▼
 Private DNS Zone
(privatelink.blob.core.windows.net)
            │
            ▼
      Storage Account
```

---

# Resources

| Resource | Name |
|----------|------|
| Storage Account | stcoredevweud0e8d4 |
| Private Endpoint | pe-storage-dev-weu |
| Private DNS Zone | privatelink.blob.core.windows.net |
| Virtual Network | vnet-core-dev-weu |
| Resource Group | rg-core-dev-weu |

---

# Why Private Endpoints?

A Private Endpoint assigns a private IP address from the Virtual Network to an Azure PaaS service.

Applications inside the VNet communicate with the service over private networking instead of the public Internet.

Benefits include:

- Eliminates public exposure
- Improves security posture
- Supports Zero Trust architectures
- Uses Microsoft's private backbone
- Enables secure communication between Azure resources

---

# DNS Resolution

The environment includes a Private DNS Zone:

```
privatelink.blob.core.windows.net
```

The Private DNS Zone automatically resolves the Storage Account Blob endpoint to the Private Endpoint IP address.

Without Private DNS, resources inside the VNet would continue resolving the public Storage Account endpoint.

---

# Traffic Flow

```
Application
      │
      ▼
DNS Query
      │
      ▼
Private DNS Zone
      │
      ▼
Private Endpoint
      │
      ▼
Storage Account
```

Traffic never leaves the Microsoft Azure backbone.

---

# Deployment

The Private Endpoint is deployed automatically using PowerShell and GitHub Actions as part of the infrastructure deployment pipeline.

Deployment is fully idempotent.

Running the deployment multiple times will not create duplicate resources.

---

# Validation

## Azure Portal

Navigate to:

```
Resource Group
    ↓
Private Endpoint
    ↓
Overview
```

Verify:

- Status = Approved
- Connection State = Approved

---

Navigate to:

```
Private Endpoint
    ↓
DNS Configuration
```

Verify:

- Private IP Address exists
- Blob FQDN is mapped correctly

---

Navigate to:

```
Private DNS Zone
    ↓
Record Sets
```

Verify:

- Storage Account record exists
- Record points to the Private Endpoint IP

---

# PowerShell Validation

Verify the Private Endpoint:

```powershell
Get-AzPrivateEndpoint `
    -ResourceGroupName rg-core-dev-weu
```

Verify the Private DNS Zone:

```powershell
Get-AzPrivateDnsZone `
    -ResourceGroupName rg-core-dev-weu
```

Verify DNS Records:

```powershell
Get-AzPrivateDnsRecordSet `
    -ZoneName privatelink.blob.core.windows.net `
    -ResourceGroupName rg-core-dev-weu
```

---

# AZ-104 Concepts

This deployment reinforces the following AZ-104 objectives:

- Private Endpoint
- Private DNS Zone
- Secure access to Azure Storage
- Network isolation
- Hybrid networking fundamentals
- Storage networking
- DNS resolution
- Enterprise security

---

# Enterprise Notes

Private Endpoints are commonly used to secure Azure PaaS services such as:

- Storage Accounts
- Key Vault
- Azure SQL Database
- Cosmos DB
- App Configuration
- Recovery Services Vault

In production environments, organizations typically combine:

- Private Endpoints
- Network Security Groups
- Azure Firewall
- Private DNS Zones
- Managed Identity
- RBAC

to eliminate unnecessary public exposure and enforce secure, identity-based access across Azure services.
