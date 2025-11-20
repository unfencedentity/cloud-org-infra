# 📦 Data Layer Overview – cloud-org-infra

This document provides a clear and user-friendly overview of the **data layer** implemented in the `cloud-org-infra` project.  
It explains how the Storage Account is configured, why ADLS Gen2 is used, and how secure access is enforced using private networking and RBAC.

---

# 1. Storage Account Overview

**Name:** `stdeweu2401`  
**Region:** `westeurope`  
**Type:** `StorageV2` (General Purpose v2)  
**Security Model:** RBAC-only (no access keys)  
**Public Access:** Disabled (private access only)  
**Data Layer:** ADLS Gen2 (Hierarchical Namespace enabled)

ADLS Gen2 enables:
- directory & file-level permissions (POSIX-style ACLs)  
- scalable data lake workflows  
- compatibility with Azure ML, Synapse, Databricks, etc.  
- enterprise-compliant security  

---

# 2. Why ADLS Gen2?

| Feature | Benefit |
|--------|---------|
| Hierarchical namespace | Folders + ACLs, better for data engineering |
| Optimized for analytics | High-throughput workloads |
| RBAC integration | No shared keys, identity-first architecture |
| Private Link support | No public traffic |
| Multi-protocol support | Blob API + DFS API |

The data layer is prepared for both automation and future big-data workloads.

---

# 3. Private Endpoints

Private endpoints ensure the storage account is NEVER accessible from the public internet.

| Endpoint Type | Name | Purpose |
|---------------|------|---------|
| Blob | `pep-stdeweu2401-blob` | Private blob access |
| DFS  | `pep-stdeweu2401-dfs`  | Secure access to file system (ADLS Gen2) |

These endpoints live inside **subnet-data**.

---

# 4. Private DNS Zones

To support private endpoints, two DNS zones were created:

| DNS Zone | Used For |
|----------|----------|
| `privatelink.blob.core.windows.net` | Blob endpoint resolution |
| `privatelink.dfs.core.windows.net`  | DFS endpoint resolution |

Apps inside the VNet automatically resolve the private IPs associated with these endpoints.

---

# 5. Security Model

The storage account follows enterprise security guidelines:

### ✔ RBAC-Only Access  
No access keys are used.  
Roles are assigned **per identity** (user or managed identity).

Example role:
- **Storage Blob Data Contributor**

### ✔ Public Network Access Disabled  
All requests must come through:
- VNet  
- Private Endpoints  
- Private DNS zones  

### ✔ Segmentation by Subnet  
Data subnet is isolated from the application subnet.

---

# 6. Intended Use Cases

This data layer is suitable for:

- App Service or Function Apps storing files  
- Automation accounts or pipelines writing logs  
- Terraform state (future)  
- Analytics workloads (Synapse, Databricks, ML)  
- General organization data lake foundations

---

# 7. Future Expansions

Future additions can extend the data platform:

- Key Vault integration for secure SAS/credential flows  
- Access control via Managed Identities  
- ACR (container registry) private endpoint  
- SQL private endpoint  
- Data ingestion pipelines  
- Backup & retention policies  
- Azure Monitor Diagnostics export  

---

# 📌 Status  
Data layer is **secure**, **private**, and fully aligned with enterprise best practices.  
It is a foundation for both application workloads and advanced data engineering pipelines.
