# 🔐 Security Overview – cloud-org-infra

This document describes the **security model** used in the `cloud-org-infra` project.  
It focuses on how access is controlled, how data is protected, and how the network is isolated.

---

# 1. Security Principles

The project follows these core security principles:

- **Least privilege** – Identities receive only the permissions they need.  
- **Identity over keys** – Prefer **Managed Identities** and **RBAC**, avoid shared keys.  
- **Private by default** – Services are exposed only over **private endpoints** where possible.  
- **Segmentation** – Network is split into subnets by role (apps / data / services).  
- **Repeatability** – Security configuration is applied via scripts/modules, not manual clicks.

These principles are reflected in each layer: identity, network, data, and platform services.

---

# 2. Identity & Access Management (IAM)

The project uses **Azure RBAC** as the primary access control mechanism.

Key characteristics:

- Access is granted to **users** or **Managed Identities**, not to shared secrets.  
- Role assignments are scoped to the minimum necessary level (resource / resource group).  

Example roles used:

- **Storage Blob Data Contributor**  
  - Scope: Storage account  
  - Used by: users or managed identities that need to read/write blob data.  

This approach avoids:
- long-lived keys  
- connection strings in code  
- hard-coded credentials

---

# 3. Network Security

The network is designed to **minimize exposure**:

- A single VNet with multiple subnets:  
  - `core-services` – shared internal components  
  - `apps` – application hosting (future)  
  - `data` – private endpoints and data plane access  

- Private endpoints are used for:
  - **Blob** access  
  - **DFS (ADLS Gen2)** access  

- Private DNS zones ensure that name resolution for `blob` and `dfs` uses **private IPs**.

Result:  
Traffic between applications and storage **never leaves Azure’s internal network**.

---

# 4. Data Protection

The Storage Account (`stdeweu2401`) is configured with:

- **ADLS Gen2 (Hierarchical Namespace)** – enables ACLs and structured permissions.  
- **Public Network Access: Disabled** – no direct internet access.  
- **RBAC-only access** – no shared keys used by design.  

This means:

- All data access is authenticated through Azure AD.  
- All traffic flows through private endpoints, not public endpoints.  
- The account is ready for advanced data security (ACLs, per-folder permissions).

---

# 5. Governance & Tagging

To support visibility and governance, all core resources are tagged with:

- `owner` – who is responsible for the resource  
- `env` – environment (e.g. dev)  
- `app` – logical application or system name  

These tags support:

- cost allocation  
- cleanup / lifecycle management  
- filtering in Azure Portal and CLI  
- policy enforcement (future)

---

# 6. Current Security Scope

Today, the implemented security controls cover:

- Storage Account private access  
- Data-layer protection (ADLS Gen2 + private endpoints + RBAC)  
- Network segmentation via subnets  
- Foundational RBAC roles for data access  

This is a solid baseline for an enterprise-grade environment.

---

# 7. Planned Security Enhancements

As the platform grows, the following will be added:

- Network Security Groups (NSGs) per subnet  
- Azure Policy for:
  - enforcing tags  
  - blocking public IPs on critical resources  
  - enforcing naming and regions  
- Key Vault with private endpoints (secrets, certificates, keys)  
- Managed Identities for applications, wired to Key Vault and Storage  
- Diagnostic settings for Security Center / Defender plans  

---

# 📌 Status

Security is **not an afterthought** in `cloud-org-infra`.  
The current design emphasizes:

- private-only data paths  
- identity-based access  
- structured tagging and governance  

It is ready to be extended with more advanced security controls as additional services are onboarded.
