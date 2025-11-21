# 🖥️ Compute Overview – cloud-org-infra

This document summarizes how the **compute layer** is designed in the `cloud-org-infra` project and how it is expected to evolve as applications are added.

---

# 1. Role of the Compute Layer

The compute layer is responsible for:

- Running application code (APIs, web apps, background jobs)  
- Connecting securely to data (Storage, Key Vault, databases)  
- Integrating with the network (VNet, subnets, private endpoints)  
- Using managed identities for secure access  

The infrastructure is intentionally designed so that **compute can be added without redesigning the foundation**.

---

# 2. Current State

At this stage, the project defines:

- A **VNet subnet dedicated to applications**:
  - `apps` subnet (`10.20.2.0/24`)
  - Intended for:
    - App Service VNet Integration
    - Container Apps
    - Functions or future AKS nodes (if needed)

- A **data subnet** used for private endpoints:
  - Allows compute workloads to resolve and reach:
    - ADLS Gen2 Storage via private endpoints
    - Future Key Vault, ACR, SQL private endpoints  

- A **core-services subnet**:
  - For shared components such as monitoring, automation, and control-plane tooling.

Even without active app workloads deployed yet, the **network and security layout are fully prepared** to host them.

---

# 3. Planned Compute Components

The following components are planned to be added as the platform evolves:

### 3.1. App Service Plan + Web App

- **App Service Plan** (Linux-based)  
- **Web App** (e.g. Python or .NET runtime)  
- **Managed Identity enabled**  
- VNet integration with the `apps` subnet  
- Access to:
  - Storage (ADLS Gen2) via RBAC  
  - Key Vault (for configuration and secrets)  

This will allow:
- secure file storage  
- secure configuration loading  
- internal-only HTTP calls if needed  

---

### 3.2. Container-Based Workloads (Future)

Possible additions include:

- **Azure Container Apps** or **AKS** for containerized workloads  
- Private access to:
  - Storage  
  - Key Vault  
  - Databases  
- CI/CD integration from GitHub Actions for image builds and deployments  

This would enable microservices, workers, or batch jobs to run inside the same secure network.

---

# 4. Integration with the Rest of the Platform

The compute layer is tightly integrated with:

- **Network layer**:
  - Dedicated subnet for apps  
  - Route to data via internal IPs only  
- **Data layer**:
  - Storage accessed via private endpoints and RBAC  
- **Security layer**:
  - Managed identities instead of secrets  
  - Future NSGs for traffic control  
- **Automation layer**:
  - PowerShell / Terraform modules to deploy compute consistently  

---

# 5. Design Goals

The compute design follows these goals:

- **No hard-coded secrets**  
- **No public endpoints when avoidable**  
- **Everything deployable via code**  
- **Easy to onboard new applications**  
- **Ready for scale-out and multi-environment setups** (dev/test/prod)

---

# 6. Next Steps for Compute

The next concrete steps for the compute layer are:

1. Create an **App Service Plan** in the core resource group.  
2. Deploy a **sample Web App** with:
   - Managed Identity enabled  
   - VNet integration configured  
3. Grant **RBAC access** for the Web App’s identity to:
   - Storage (Blob Data Contributor)  
   - Future Key Vault (Secret Reader)  
4. Add **runbooks and documentation** for:
   - how to deploy apps  
   - how to grant access via RBAC  
   - how to connect securely to the data layer  

---

# 📌 Status

The compute layer is currently in a **ready-to-host** state:

- Network and data paths are already in place  
- Security model (RBAC + private endpoints) is defined  
- Subnets are segmented for apps vs. data vs. services  

What remains is to start deploying concrete workloads (App Services, containers, Functions) using the existing automation patterns.
