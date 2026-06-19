# cloud-org-infra Documentation

Welcome to the cloud-org-infra documentation hub.

This section contains detailed implementation guides, architecture references, deployment workflows, monitoring configurations, security controls, backup procedures, and operational standards used throughout the project.

The project demonstrates enterprise-style Azure infrastructure automation using PowerShell, GitHub Actions, OIDC authentication, Azure RBAC, and Infrastructure-as-Code principles.

---

# Documentation Structure

## Core Infrastructure

Foundational Azure resources used throughout the environment.

| Document | Description |
|-----------|-----------|
| create-rg.md | Resource Group deployment and governance |
| create-network.md | Virtual Network and subnet provisioning |
| create-nsgs.md | Network Security Group deployment and configuration |
| create-storage.md | Storage Account deployment |
| create-keyvault.md | Azure Key Vault deployment and secret management |

---

## Monitoring & Observability

Centralized monitoring, diagnostics, telemetry, and operational visibility.

| Document | Description |
|-----------|-----------|
| create-loganalytics.md | Log Analytics Workspace deployment |
| create-diagnostics.md | Centralized Diagnostic Settings |
| create-appinsights.md | Application Insights deployment |
| create-alerts.md | Monitoring alerts and operational notifications |

---

## Application Platform

Application hosting and workload configuration.

| Document | Description |
|-----------|-----------|
| create-appservice.md | App Service Plan and Web App deployment |
| create-appservice-extended.md | Enterprise App Service configuration |

---

## Backup & Recovery

Business continuity and disaster recovery components.

| Document | Description |
|-----------|-----------|
| create-recoveryservicesvault.md | Recovery Services Vault deployment |
| create-backuppolicy.md | Backup Policy deployment |
| create-vmbackup.md | Virtual Machine Backup Protection |
| backup-and-recovery.md | End-to-end backup and restore workflow |

---

## Security & Identity

Authentication, authorization, and access management.

| Document | Description |
|-----------|-----------|
| oidc-authentication.md | GitHub OIDC authentication |
| create-keyvault.md | Secure secret management |
| create-appservice-extended.md | Managed Identity integration |

---

## Deployment & Operations

Deployment processes and operational workflows.

| Document | Description |
|-----------|-----------|
| deployment-flow.md | End-to-end deployment process |
| architecture.md | Environment architecture overview |
| lessons-learned-diagnostics.md | Diagnostics implementation lessons learned |

---

# Architecture Overview

cloud-org-infra currently includes:

- Azure Resource Groups
- Virtual Networks
- Subnets
- Network Security Groups
- Storage Accounts
- ADLS Gen2
- Azure Key Vault
- Log Analytics Workspace
- Diagnostic Settings
- Application Insights
- App Service Plans
- Web Apps
- Managed Identities
- Recovery Services Vault
- Backup Policies
- VM Backup Protection
- Azure RBAC
- GitHub Actions
- OIDC Authentication

---

# Deployment Model

Developer
↓
Git Commit
↓
GitHub Repository
↓
GitHub Actions
↓
OIDC Authentication
↓
Azure Deployment
↓
Resource Validation
↓
Monitoring & Observability

---

# Design Principles

The project follows the following principles:

- Idempotent deployments
- Infrastructure automation
- Enterprise naming standards
- Governance through tagging
- Security-first design
- Observability by default
- Documentation-driven implementation
- Repeatable deployment workflows

---

# Learning Objectives

This project was built to develop practical skills in:

- Azure Administration (AZ-104)
- Azure Architecture
- Infrastructure Automation
- PowerShell
- GitHub Actions
- Azure Security
- Monitoring & Observability
- Backup & Recovery
- Enterprise Cloud Operations

---

# Future Roadmap

Planned future enhancements include:

- Azure Monitor
- Action Groups
- Azure Policy
- Management Groups
- Private Endpoints
- Azure Bastion
- Load Balancer
- Application Gateway
- Front Door
- VPN Gateway
- ExpressRoute
- Terraform
- AKS

---

# Project Status

Current Release:

v1.0.0

Status:

Active Development

Repository:

cloud-org-infra
