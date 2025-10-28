# Azure Environment Setup — Personal Lab

## Overview
This document describes the initial setup of the Azure environment used for automation testing and IaC development.

---

## 1. Tenant and Subscription
- **Account:** lucian.micro@gmail.com
- **Directory:** Default Directory
- **Subscription Type:** Pay-As-You-Go
- **Region:** West Europe (Amsterdam)
- **Purpose:** Personal learning and proof-of-concept (IaC, GitHub Actions, Automation)

---

## 2. Initial Configuration
- Created via [portal.azure.com](https://portal.azure.com)
- Verified identity with credit card (no prepaid, no virtual)
- Confirmed access to:
  - Azure Resource Manager (ARM)
  - Azure Portal
  - Cost Management + Billing

---

## 3. Cost Protection
- Set budget to **5 EUR/month**
- Enabled cost alerts at 50%, 80%, and 100%
- Sandbox rule: delete all resources after validation

---

## 4. Validation
- Resource Group created and deleted successfully: `rg-lucian-cloud`
- Confirmed permissions and default policy inheritance.
- Ready for dry-run deployment testing via PowerShell and GitHub Actions.

---

## 5. Next Steps
- Link Azure subscription to GitHub secrets for CI/CD automation
- Define baseline IaC structure (`cloud-deploy-blueprint`)
- Deploy minimal Resource Group + Storage Account as validation
