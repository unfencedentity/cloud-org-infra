%%{init: {"flowchart": { "rankdir":"TB", "nodeSpacing": 40, "rankSpacing": 45 }, "themeVariables": { "fontSize": "14px" }}}%%
flowchart TB

subgraph Users["Consumers / Internal Clients"]
  U1[Developer / Service]
end

subgraph Compute["Compute (rg-dev-weu)"]
  ASP[App Service Plan\nplan-core-weu]
  APP[Web App\napp-core-weu\nRuntime: PYTHON 3.10\nManaged Identity]
  ASP --> APP
end

subgraph Network["Network (rg-dev-weu)"]
  VNET[VNet vnet-org-dev-weu\n10.20.0.0/16]
  S1[(subnet-core-services\n10.20.1.0/24)]
  S2[(subnet-apps\n10.20.2.0/24\nDelegation: Microsoft.Web/serverFarms)]
  S3[(subnet-data\n10.20.3.0/24)]
  VNET --- S1
  VNET --- S2
  VNET --- S3
end

subgraph Data["Data"]
  SA[(Storage Account\nstdeweu2401\nADLS Gen2\nHNS: true)]
  PEB[[PE: blob]]
  PED[[PE: dfs]]
  SA --- PEB
  SA --- PED
end

subgraph DNS["Private DNS"]
  DNSB[(privatelink.blob.core.windows.net)]
  DNSD[(privatelink.dfs.core.windows.net)]
  DNSB -.-> PEB
  DNSD -.-> PED
end

subgraph Security["Security & Access"]
  RBAC[RBAC: Storage Blob Data Contributor → Web App MI]
  PUBOFF[PublicNetworkAccess = Disabled]
end

U1 -->|HTTPS (via VNet Integration)| APP
APP -->|Private name resolution| DNS
APP -->|Private Link traffic| VNET
VNET -->|to PE endpoints| Data
RBAC -. Identity-based access .- APP
PUBOFF -. Enforced .- SA
