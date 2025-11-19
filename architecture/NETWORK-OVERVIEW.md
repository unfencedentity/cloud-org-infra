# 🛰️ Network Overview – cloud-org-infra

This document provides a clear, developer-friendly summary of the **networking layer** used in the `cloud-org-infra` project.  
It describes how the virtual network is structured, what each subnet is used for, and how security boundaries are created.

---

# 1. Virtual Network

**Name:** `vnet-org-dev-weu`  
**Address Space:** `10.20.0.0/16`  
**Region:** `westeurope`

The VNet provides isolated internal networking for applications, data, and shared services.  
All resources are kept private and integrate using private endpoints where possible.

---

# 2. Subnet Layout

| Subnet Name       | CIDR           | Purpose / Role |
|-------------------|----------------|----------------|
| core-services     | 10.20.1.0/24   | Shared platform components, monitoring, automation, future services |
| apps              | 10.20.2.0/24   | Application hosting (App Service VNet Integration, containers, Functions) |
| data              | 10.20.3.0/24   | Private endpoints (Storage, Key Vault, future databases) |

This separation enforces:
- network isolation  
- minimal blast radius  
- cleaner routing  
- easier NSG management  

---

# 3. Private Endpoints (Data Subnet)

| Service | Endpoint | Purpose |
|---------|----------|---------|
| Storage (Blob) | `pep-st-blob` | Secure data access without public internet |
| Storage (DFS)  | `pep-st-dfs`  | ADLS Gen2 hierarchical namespace access |

These endpoints live in **subnet-data**, and DNS is resolved via dedicated private DNS zones.

---

# 4. Private DNS Zones

| Zone Name | Used For |
|-----------|----------|
| `privatelink.blob.core.windows.net` | Blob endpoint resolution |
| `privatelink.dfs.core.windows.net`  | Data Lake DFS traffic |

These guarantee that application traffic stays inside Azure’s backbone network.

---

# 5. Security & Access

The network model is aligned with enterprise standards:

- No public endpoints for storage  
- RBAC-only data access  
- Segmented subnets for layered security  
- Private link routing through VNet  
- Ready for NSGs and UDRs (future expansion)  

---

# 6. Future Enhancements

The networking layer is designed to expand naturally with:

- NSGs for each subnet  
- UDR tables for traffic control  
- Azure Firewall / WAF  
- Private endpoints for Key Vault, ACR, SQL  
- Hub-Spoke architecture for multiple environments  
- Global routing (Azure DNS + Traffic Manager)  

---

# 📌 Status  
Network layer is **functional**, **clean**, and **enterprise-ready**.  
Suitable for app hosting, automation workflows, and secure data traffic.
