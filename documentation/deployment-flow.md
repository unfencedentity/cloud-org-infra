# Deployment Flow

## Purpose

This document describes how cloud-org-infra is deployed from GitHub into Azure using GitHub Actions, OIDC authentication, and PowerShell automation.

---

## High-Level Flow

Developer
↓
Git Commit
↓
Git Push
↓
Branch (develop)
↓
Pull Request
↓
Merge to main
↓
GitHub Actions
↓
OIDC Authentication
↓
Azure PowerShell
↓
Azure Resource Deployment

---

## Deployment Components

### Source Control

- Git
- GitHub Repository
- Branch Strategy (main / develop)

### CI/CD Platform

- GitHub Actions

### Authentication

- Microsoft Entra ID
- Service Principal
- OIDC
- Federated Credentials

### Deployment Engine

- PowerShell
- Az PowerShell Modules

### Target Platform

- Microsoft Azure

---

## GitHub Actions Workflow

Workflow:

```text
.github/workflows/deploy.yml
```

Main responsibilities:

- Checkout repository
- Authenticate to Azure using OIDC
- Install required Az modules
- Execute deployment orchestration script

---

## Authentication Flow

GitHub Actions does not use client secrets.

Authentication is performed using:

```text
GitHub Actions
↓
OIDC Token
↓
Federated Credential
↓
Service Principal
↓
Azure Subscription
```

Benefits:

- No secret rotation
- Reduced credential exposure
- Enterprise-grade authentication

---

## Deployment Orchestration

Main deployment script:

```text
automation/deploy-environment.ps1
```

This script orchestrates all infrastructure modules.

Examples:

- Resource Groups
- Networking
- Storage
- Key Vault
- App Services
- Log Analytics
- Monitoring
- Backup

---

## Idempotent Design

Deployments are designed to be idempotent.

Running the same deployment multiple times:

- Does not recreate existing resources
- Does not produce duplicate infrastructure
- Updates resources only when required

---

## Deployment Validation

Validation is performed by:

- GitHub Actions logs
- Azure Activity Log
- Resource Group validation
- Resource existence checks
- Recovery point validation (Backup)

---

## AZ-104 Keywords

- GitHub Actions
- CI/CD
- OIDC
- Federated Credentials
- Service Principal
- Azure PowerShell
- Idempotency
- Automation
- Infrastructure as Code
- Deployment Validation

---

## Interview Summary

cloud-org-infra uses GitHub Actions with OIDC authentication to deploy Azure infrastructure through PowerShell automation. Deployments are idempotent, secure, and follow enterprise CI/CD practices without storing Azure credentials in GitHub.
