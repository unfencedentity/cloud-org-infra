# Infrastructure Overview

This diagram provides a high-level view of the core Azure infrastructure used for the environment.  
It highlights the main layers and how they interact:

- **Compute Layer** — Azure App Service hosting the web app (Python 3.10, Managed Identity).
- **Network Layer** — Virtual Network (VNet) with segregated subnets for core services, apps, and data.
- **Data Layer** — ADLS Gen2 storage account with private endpoints for secure blob and DFS access.
- **Private DNS** — Name resolution for private endpoints.
- **Security & Access** — Identity-based access control (RBAC) and restricted public network access.

Below is the visual representation of the architecture:


```mermaid
%%{init: {"flowchart": { "rankdir":"TB", "nodeSpacing": 40, "rankSpacing": 45 }, "themeVariables": { "fontSize": "14px" }}}%%
flowchart TB

subgraph Users["Consumers / Internal Clients"]
  U1[Developer / Service]
end

subgraph Compute["Compute Layer - rg-dev-weu"]
  ASP[App Service Plan - plan-core-weu]
  APP[Web App - app-core-weu - Runtime: PYTHON 3.10 - Managed Identity]
  ASP --> APP
end

subgraph Network["Network Layer - rg-dev-weu"]
  VNET[VNet vnet-org-dev-weu - 10.20.0.0/16]
  S1[(subnet-core-services - 10.20.1.0/24)]
  S2[(subnet-apps - 10.20.2.0/24 - Delegation: Microsoft.Web/serverFarms)]
  S3[(subnet-data - 10.20.3.0/24)]
  VNET --- S1
  VNET --- S2
  VNET --- S3
end

subgraph Data["Data Layer"]
  SA[(Storage Account - stdeweu2401 - ADLS Gen2 - HNS: true)]
  PEB[[Private Endpoint: blob]]
  PED[[Private Endpoint: dfs]]
  SA --- PEB
  SA --- PED
end

subgraph DNS["Private DNS"]
  DNSB[(privatelink.blob.core.windows.net)]
  DNSD[(privatelink.dfs.core.windows.net)]
  DNSB -.-> PEB
  DNSD -.-> PED
end

subgraph Security["Security and Access"]
  RBAC[RBAC: Storage Blob Data Contributor -> Web App MI]
  PUBOFF[PublicNetworkAccess = Disabled]
end

U1 -->|HTTPS via VNet Integration| APP
APP -->|Private name resolution| DNS
APP -->|Private Link traffic| VNET
VNET -->|to Private Endpoints| Data
RBAC -. Identity-based access .- APP
PUBOFF -. Enforced .- SA
```
