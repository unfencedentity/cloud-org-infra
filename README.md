# cloud-org-infra

A simulated organizational Azure environment designed for hands-on learning, automation practice, and portfolio demonstration.  
This project demonstrates building scalable Azure infrastructure using PowerShell and GitHub Actions (CI/CD), authenticated via OpenID Connect (OIDC) — eliminating the need for stored secrets.

---

## 1. Introduction

This repository showcases a clean, modular approach to deploying Azure environments using automation:

- Clear separation of responsibility and resource layout
- Consistent deployments through GitHub Actions pipelines
- Secure authentication using **OpenID Connect (OIDC)** instead of saved credentials
- Reusable PowerShell modules for provisioning tasks

This setup can be extended into real-world enterprise blueprints.

---

## 2. Architecture Overview

This project simulates a common organizational Azure structure:

```text
Tenant (Microsoft Entra ID)
│
└── Subscription (core-services / development / sandbox)
    │
    ├── Resource Group: rg-core
    │   └── Storage Accounts (logs, data, state)
    │   └── Shared Utilities (future: Key Vault, Container Registry, etc.)
    │
    ├── Resource Group: rg-network
    │   └── Virtual Network + Subnets (future expansion)
    │
    └── Resource Group: rg-security
        └── RBAC role assignments
        └── Azure Policy (naming, compliance & governance)
```

This keeps **core**, **network**, and **security** responsibilities clearly separated — similar to real enterprise environments.

---

## 3. Technology Stack

| Component      | Purpose                                        |
|----------------|------------------------------------------------|
| Azure          | Cloud platform where resources are deployed    |
| PowerShell     | IaC scripting engine for automation modules    |
| GitHub Actions | CI/CD workflow engine                          |
| OIDC           | Secure authentication — no stored secrets      |
| RBAC & Policy  | Org-wide governance and access control         |

---

## 4. Deployment Workflow (CI/CD)

The deployment pipeline runs through GitHub Actions:

1. Workflow is triggered (manual / push / schedule)
2. GitHub authenticates to Azure using **OIDC**
3. PowerShell modules install required Az tools
4. `deploy-environment.ps1` creates/updates resources
5. Output is logged and validated

This ensures **repeatable, consistent deployments**.

---

## 5. Folder Structure

```text
cloud-org-infra/
│
├── .github/workflows/          # CI/CD pipelines (GitHub Actions)
│   └── deploy.yml              # Deployment workflow
│
├── automation/                 # PowerShell automation logic
│   ├── deploy-environment.ps1  # Main environment deployment script
│   └── modules/                # Reusable helper functions
│
├── architecture/               # Diagrams and conceptual layouts (future)
├── policy/                     # Azure Policy definitions
├── security/                   # RBAC mappings & governance
└── documentation/              # Notes & usage guides
```

This layout keeps code, docs, and governance **separated and maintainable**.

---

## 6. How to Deploy

From GitHub UI →  
**Actions → Deploy Azure infra → Run Workflow**

No local secrets required.  
Authentication happens via **OIDC Federation**.

---

## 7. Planned Enhancements

- Add VNet subnets + NSGs
- Add Key Vault + Container Registry
- Expand tagging & naming governance
- Add monitoring setup (Log Analytics + Alerts)

---

**Status:** Active learning & development project.
