```mermaid
%%{init: {"flowchart": { "rankdir": "TB", "nodeSpacing": 40, "rankSpacing": 45 }, "themeVariables": { "fontSize": "14px" }}}%%
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
    S2[(subnet-apps\n10.20.2.0/24)\nDelegation: Microsoft.Web/serverFarms]
    VNET --> S1
    VNET --> S2
end

subgraph Storage["Storage (rg-dev-weu)"]
    SA[(Storage Account\nsaorgdevweu)]
end

subgraph Security["Security"]
    RBAC[Role-Based Access Control]
    PUBOFF[Public network access: Disabled]
end

%% Connections
U1 -->|HTTPS (via VNet Integration)| APP
APP -->|Private name resolution| DNS
APP -->|Private Link traffic| VNET
VNET -->|to Private Endpoints| SA
```
RBAC -. Identity-based access .- APP
PUBOFF -. Enforced .- SA
