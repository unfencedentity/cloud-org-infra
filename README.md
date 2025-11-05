# cloud-org-infra

A simulated organizational Azure environment designed for hands-on learning, automation practice, and portfolio demonstration.  
This project focuses on building scalable cloud infrastructure using **PowerShell**, **Azure**, and **GitHub Actions (CI/CD)** with **OIDC authentication**.

---

## 1. Introduction

This repository represents a clean, modular approach to deploying Azure resources using automation.  
The goal is to showcase how real organizations manage cloud environments:

- Clear separation of responsibility and resource organization
- Consistent deployments using CI/CD pipelines
- Secure authentication without storing secrets (OIDC)
- Reusable PowerShell modules for infrastructure tasks

This setup can be extended into a real production blueprint.

---

## 2. Architecture Overview

The environment simulates a standard Azure organizational structure:
Tenant (Microsoft Entra ID)
│
└── Subscription (Core Services / Development / Sandbox)
│
├── Resource Group: rg-core
│ ├── Storage Accounts (logs, data, state)
│ └── Shared Core Resources
│
├── Resource Group: rg-network
│ └── Virtual Network + Subnets (future expansion)
│
└── Resource Group: rg-security
└── RBAC, Policy, and Access Governance


---

## 3. Technology Stack

| Component | Purpose |
|---------|---------|
| **Azure** | Cloud platform where infrastructure is deployed |
| **PowerShell** | Scripting engine used for automation and IaC logic |
| **GitHub Actions** | CI/CD workflow engine that executes deployments |
| **OIDC Federation** | Secure authentication without storing secrets |
| **RBAC & Policy** | Organizational governance foundation |

---

## 4. Deployment Workflow (CI/CD)

The deployment pipeline runs through GitHub Actions:

1. GitHub workflow is triggered (manual / push / scheduled)
2. GitHub authenticates to Azure using **OIDC**, not stored secrets
3. PowerShell modules install and initialize the Az environment
4. `deploy-environment.ps1` provisions resources consistently
5. Output is logged and validated

---

## 5. Folder Structure
.github/workflows # CI/CD pipelines
automation/ # Deployment PowerShell scripts & modules
architecture/ # Environment topology & reference diagrams
policy/ # Azure Policy definitions (future extension)
security/ # RBAC & access configuration
documentation/ # Notes and extended usage guides


---

## 6. How to Deploy

From GitHub → Actions → `Deploy Azure infra` → Run workflow → Select environment.

No local secrets required.

---

## 7. Future Enhancements

- Add VNet + Subnets
- Enforce naming standard with Azure Policy
- Expand Core Services (Key Vault, Container Registry, Logs)
- Module-based resource tagging

---

**Status:** Active learning & development project.
