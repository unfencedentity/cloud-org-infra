# Architecture Overview

This document provides a high-level overview of the architecture implemented by the **cloud-org-infra** automation framework.  
The purpose is to describe how all modules work together to form a predictable, secure, scalable, and fully automated Azure environment.

The architecture adheres to:
- Azure Well-Architected Framework  
- Cloud Adoption Framework (CAF)  
- Enterprise Landing Zone principles  
- Secure-by-default IaC patterns  
- Modular orchestration and idempotent provisioning  

---

# 1. Architectural Goals

The framework is designed to achieve:

• **Consistency** — every environment is identical, reproducible, and deterministic  
• **Modularity** — each Azure component is built by a dedicated module  
• **Security** — least-privilege RBAC, managed identities, and zero-secrets pattern  
• **Observability** — full integration with Log Analytics + App Insights  
• **Scalability** — works for single app or multi-tenant enterprise workloads  
• **Automation-first** — no manual steps, no GUI dependency  
• **Idempotency** — safe repeated executions  

---

# 2. High-Level Architecture

cloud-org-infra is structured as a modular automation framework:

Core provisioning modules executed via a central orchestrator:

• create-rg.ps1  
• create-network.ps1  
• create-nsgs.ps1  
• create-storage.ps1  
• create-keyvault.ps1  
• create-appservice.ps1  
• create-loganalytics.ps1  
• create-appinsights.ps1  
• create-appservice-extended.ps1  
• create-alerts.ps1  
• create-rbac.ps1  

Each module follows the same internal structure:  
parameters → naming → validation → idempotency → provisioning → return object.

---

# 3. Environment Model

Each environment is parameterized using:

Environment: dev / test / prod  
App: core (or any application identifier)  
Region: weu / neu / uks  
Location: real Azure region name (westeurope, northeurope etc.)

Every environment is isolated and created predictably using the same structure.

---

# 4. Naming Architecture

A strict naming convention ensures deterministic resource names:

Resource Group: rg-<app>-<env>-<region>  
Virtual Network: vnet-<app>-<env>-<region>  
Subnet: snet-<app>-<env>-<region>-<purpose>  
Storage Account: st<app><env><region><unique>  
Key Vault: kv-<app>-<env>-<region>  
App Service Plan: asp-<app>-<env>-<region>  
Web App: app-<app>-<env>-<region>  
Log Analytics: law-<app>-<env>-<region>  
App Insights: appi-<app>-<env>-<region>  

Naming is lowercase, deterministic, and fully Azure-compliant.

---

# 5. Security Architecture

Security is built into every component.

## Identity
• System-assigned managed identity for App Service  
• Azure AD OIDC for GitHub Actions (no secrets)  
• No creds stored in repo  

## RBAC (via create-rbac.ps1)
• Contributor → automation identity  
• Reader → operators  
• Key Vault Secrets User → workloads  

## Key Vault
• One vault per environment  
• Centralized secrets  
• Supports private endpoints (future)  

The entire framework enforces **least privilege**.

---

# 6. Network Architecture

Provisioned components:

• Virtual Network  
• Segmented subnets  
• NSGs per subnet  
• Explicit allow/deny rules  
• Isolation between environments  
• Optional private endpoints (future)  

The network is deterministic and repeatable.

---

# 7. Observability Architecture

Monitoring is not optional—it's built-in:

### Log Analytics Workspace
• Central ingestion point  
• Retention configurable  
• Connected to App Insights and diagnostic logs  

### Application Insights
• Web App telemetry  
• Dependency tracking  
• Live Metrics (future optional)  

### Alerts
Provisioned alerts include:
• CPU high  
• HTTP 5xx spike  
• Action Group notifications  

Together, they create a full observability pipeline.

---

# 8. Application Architecture (App Service)

App Services are deployed in two phases:

### Base deployment (create-appservice.ps1)
• App Service Plan  
• Web App  
• Tags  
• Naming conventions  
• Idempotency  

### Extended configuration (create-appservice-extended.ps1)
• HTTPS only  
• TLS 1.2 minimum  
• Managed Identity  
• Always On  
• Diagnostic logs to LAW  

This ensures enterprise-grade hosting by default.

---

# 9. Orchestration Architecture

`deploy-environment.ps1` acts as the single source of truth for orchestration.

Execution flow:

1. Resource Group  
2. Virtual Network  
3. NSGs  
4. Storage Account  
5. Key Vault  
6. Log Analytics Workspace  
7. App Service  
8. Application Insights  
9. App Service Extended Configuration  
10. Alerts  
11. RBAC  

All steps support ShouldProcess, have clean logs, and enforce idempotency.

---

# 10. CI/CD Architecture (Future)

The architecture is built to be easily automated:

• GitHub Actions OIDC authentication  
• Multi-environment deploy workflows  
• Tag-based releases  
• Automated documentation and change tracking  

This allows cloud-org-infra to act as a **cloud foundation platform**.

---

# 11. Terraform Mirror Architecture (cloud-org-infra2)

A 1:1 Terraform mirror is planned:

• Same naming conventions  
• Same modules  
• Same orchestration  
• Same output expectations  

This allows organizations to choose PowerShell or Terraform without losing structure.

---

# 12. Summary

`cloud-org-infra` is engineered as a modular, secure, deterministic, production-grade cloud foundation.

It provides:

• predictable deployments  
• strong security posture  
• full observability  
• clean automation  
• enterprise-grade documentation  
• extensibility for any cloud project  

This architecture ensures consistent, scalable Azure environments suitable for enterprise and product use cases.
