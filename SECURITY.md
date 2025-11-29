# Security Model

This document describes the **security architecture** of the `cloud-org-infra` automation
toolkit, including identity boundaries, RBAC patterns, secret management, network controls,
and operational security expectations.

The goal is to provide a **clear, auditable security baseline** that organizations can adopt
when deploying Azure resources using this automation.

---

# 1. Identity & Authentication

## 1.1 Azure Authentication Method
The automation uses **Azure Federated Identity (OIDC)** by default when executed from
GitHub Actions. This eliminates the need for stored service principal secrets.

Local execution may use:
- `Connect-AzAccount` (interactive)
- Service Principal credentials via environment variables  
  (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_SECRET`).

## 1.2 Least Privilege Access
Each automation identity (GitHub workflow identity or local SP) should have:

| Scope | Role |
|-------|-------|
| Subscription | **Contributor** or custom role limited to resource types created by this toolkit |
| Resource Group | Managed by automation only |
| Key Vault | **Key Vault Administrator** during provisioning, **Key Vault Secrets Officer** afterwards |

No human operators should require write permissions in production unless break-glass.

---

# 2. Role-Based Access Control (RBAC)

## 2.1 RBAC Module
`create-rbac.ps1` provisions standardized RBAC assignments at the Resource Group level.

Default roles provisioned:
- **Reader** — baseline visibility for operators & auditors  
- **Contributor** — for automation or CI/CD identity  
- **Key Vault Secrets User** — minimal secrets access for workloads  

RBAC assignments follow the naming convention:

rbac-<app>-<env>-<region>

## 2.2 Principle of Separation  
Administrative roles are kept separate:
- Operators: Reader  
- Workload services: minimal (MSI or Secrets User)  
- Automation identity: Contributor  

Human identities do **not** receive Contributor rights by default.

---

# 3. Secret & Credential Management

## 3.1 Key Vault Usage
A dedicated Azure Key Vault per environment/app/region is created via:

create-network.ps1
create-nsgs.ps1

Patterns:
- Dedicated subnets per workload tier
- NSG rules enforced at subnet level
- No public inbound traffic unless explicitly configured

## 4.2 Private Endpoints (optional)
Modules support enabling:
- Private Endpoint for Key Vault
- Private DNS zone integration

This prevents public access to sensitive resources.

---

---

# 6. Monitoring & Alerting Security

## 6.1 Observability Stack
Created by:
- `create-loganalytics.ps1`
- `create-appinsights.ps1`

All logs and metrics flow into centralized workspaces.

## 6.2 Alerts
`create-alerts.ps1` provisions:
- CPU threshold alerts  
- HTTP 5xx spike alerts  
- Action Groups for routing notifications  

Ensures incident detection for mission-critical workloads.

---

# 7. Governance & Policy (Optional)

The `/policy` folder contains:
- naming convention templates  
- baseline Azure Policy prototypes  
- governance checklist  

Future versions may enforce:
- Allowed SKUs  
- Mandatory private endpoints  
- Restrict public IPs  
- Enforce tags  

---

# 8. Security Operations Expectations

Teams adopting this toolkit should:
1. Rotate credentials periodically  
2. Store no secrets in Git  
3. Use Managed Identity where possible  
4. Maintain strict RBAC boundaries  
5. Review alerts & monitoring outputs  
6. Audit KeyVault and RBAC changes regularly  

---

# 9. Compliance & Auditability

This automation aligns with:
- ISO 27001 control structure  
- Azure Well-Architected Framework  
- Cloud Adoption Framework (CAF) governance model  
- Microsoft Enterprise Landing Zone patterns  

---

# 10. Disclaimer

This toolkit provides a **security baseline**, not a full enterprise security system.
Organizations should adapt modules and RBAC models to their own compliance requirements.



# 5. Application Security Controls

## 5.1 App Service Baseline
The automation applies hardened defaults:

- HTTPS Only  
- Minimum TLS 1.2  
- Disable FTP  
- Disable remote debugging  
- System Assigned Identity enabled  
- Diagnostic logs streamed to Log Analytics  

Extended configurations are managed in:

create-appservice-extended.ps1
