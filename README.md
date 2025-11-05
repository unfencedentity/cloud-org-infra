# cloud-org-infra

A simulated organizational Azure environment designed for hands-on learning, automation practice, and portfolio demonstration.

This project focuses on building scalable cloud infrastructure using **PowerShell**, **Azure**, and **GitHub Actions (CI/CD)** with **OIDC authentication** (no stored secrets).

---

## 1. Introduction

This repository represents a clean and modular approach to deploying Azure resources using automation.

The goal is to show how real organizations structure and manage cloud environments:

- Clear separation of responsibility and resource organization
- Consistent deployments using CI/CD pipelines
- Secure authentication **without storing secrets** (OIDC)
- Reusable PowerShell modules for infrastructure tasks

This setup can be extended into a real **production-style blueprint**.

---

## 2. Architecture Overview

This project simulates a standard organizational Azure structure:

```
Tenant (Microsoft Entra ID)
│
└── Subscription (core-services / development / sandbox)
    │
    ├── Resource Group: rg-core
    │   ├── Storage Accounts (data, logs, state)
    │   └── Shared Utilities (future: Key Vault, Container Registry, etc.)
    │
    ├── Resource Group: rg-network
    │   └── Virtual Network + Subnets (future expansion)
    │
    └── Resource Group: rg-security
        ├── RBAC role assignments
        └── Azure Policy (naming, compliance & governance)
```

This structure keeps **core**, **network**, and **security** responsibilities separated — similar to real enterprise cloud environments.

---

## 3. Technology Stack

| Component        | Purpose                                                    |
|-----------------|------------------------------------------------------------|
| **Azure**       | Cloud platform where infrastructure is deployed            |
| **PowerShell**  | Scripting engine for IaC-style modules and automation      |
| **GitHub Actions** | CI/CD workflow engine that executes deployments        |
| **OIDC Federation** | Secure authentication without secrets                  |
| **RBAC & Policy** | Organizational access and governance controls            |

---

## 4. Deployment Workflow (CI/CD)

The deployment pipeline runs through GitHub Actions:

1. Workflow is triggered (manually or via push)
2. GitHub **authenticates to Azure using OIDC** — **no secrets stored**
3. PowerShell installs required Az modules
4. `deploy-environment.ps1` provisions Azure resources consistently
5. Output is logged and validated

This ensures **repeatable, consistent deployments**.

---

## 5. Folder Structure

```
cloud-org-infra/
│
├── .github/workflows/        # CI/CD pipelines (GitHub Actions)
│   └── deploy.yml            # Deployment workflow
│
├── automation/               # PowerShell deployment scripts & modules
│   ├── deploy-environment.ps1
│   └── modules/              # Reusable functions and helpers
│
├── architecture/             # Conceptual & visual topology diagrams (future)
│
├── policy/                   # Azure Policy definitions & governance rules
│
├── security/                 # RBAC role mappings & access documentation
│
└── documentation/            # Notes, guides, and usage examples
```

This structure separates code, documentation, and operations — making the repo **maintainable and scalable**.

---

## 6. How to Deploy

From GitHub:

```
Actions → Deploy Azure infra → Run workflow → Select environment
```

No local secrets or manual auth needed.

---

## 7. Future Enhancements (Backlog)

- Add Virtual Network + subnets
- Add Azure Key Vault + Container Registry
- Expand logging + diagnostics design
- Strengthen naming/tagging policy
- Additional reusable PowerShell modules

---

**Status:** Active learning & development project.
