# cloud-org-infra Documentation

Welcome to the **cloud-org-infra** documentation hub.

This directory contains implementation guides, deployment workflows, architecture references, operational procedures, monitoring configurations, security documentation, and infrastructure design decisions used throughout the project.

The project demonstrates enterprise-style Azure infrastructure automation using PowerShell, GitHub Actions, Azure OIDC authentication, Azure RBAC, Managed Identity, Private Networking, and Infrastructure as Code principles.

---

# Documentation Structure

## Core Infrastructure

Foundational Azure resources used throughout the environment.

| Document | Description |
|-----------|-------------|
| [resource-group.md](resource-group.md) | Resource Group deployment and governance |
| [network.md](network.md) | Virtual Network and subnet provisioning |
| [nsgs.md](nsgs.md) | Network Security Group deployment and configuration |
| [storage.md](storage.md) | Storage Account and ADLS Gen2 deployment |
| [keyvault.md](keyvault.md) | Azure Key Vault deployment and secret management |
| [managed-identity.md](managed-identity.md) | User Assigned Managed Identity deployment |
| [vm.md](vm.md) | Virtual Machine deployment |
| [appservice.md](appservice.md) | App Service Plan and Web App deployment |
| [appservice-extended.md](appservice-extended.md) | Enterprise App Service configuration |

---

## Networking

Private connectivity and enterprise networking components.

| Document | Description |
|-----------|-------------|
| [network.md](network.md) | Virtual Network architecture |
| [nsgs.md](nsgs.md) | Network Security Groups |
| [private-endpoint.md](private-endpoint.md) | Private Endpoint deployment |
| [HybridConnectivity.md](HybridConnectivity.md) | Hybrid connectivity concepts |

---

## Monitoring & Observability

Centralized monitoring, diagnostics, telemetry, and operational visibility.

| Document | Description |
|-----------|-------------|
| [loganalytics.md](loganalytics.md) | Log Analytics Workspace deployment |
| [diagnostics.md](diagnostics.md) | Azure Diagnostic Settings |
| [appinsights.md](appinsights.md) | Application Insights deployment |
| [alerts.md](alerts.md) | Azure Monitor alerts |
| [healthchecks.md](healthchecks.md) | Deployment validation and health checks |
| [lessons-learned-diagnostics.md](lessons-learned-diagnostics.md) | Diagnostics implementation lessons learned |

---

## Backup & Recovery

Business continuity and disaster recovery.

| Document | Description |
|-----------|-------------|
| [recoveryservicesvault.md](recoveryservicesvault.md) | Recovery Services Vault deployment |
| [backuppolicy.md](backuppolicy.md) | Backup Policy deployment |
| [vmbackup.md](vmbackup.md) | Virtual Machine Backup |
| [snapshots.md](snapshots.md) | Managed Disk snapshots |
| [backup-and-recovery.md](backup-and-recovery.md) | End-to-end backup workflow |

---

## Security & Identity

Authentication, authorization, identity, and secure access.

| Document | Description |
|-----------|-------------|
| [managed-identity.md](managed-identity.md) | User Assigned Managed Identity |
| [keyvault.md](keyvault.md) | Azure Key Vault |
| [private-endpoint.md](private-endpoint.md) | Private networking |
| [rbac.md](rbac.md) | Azure Role-Based Access Control |

---

## Deployment & Operations

Deployment orchestration and operational workflows.

| Document | Description |
|-----------|-------------|
| [deployment-flow.md](deployment-flow.md) | End-to-end deployment process |
| [environment-lifecycle-automation.md](environment-lifecycle-automation.md) | Environment lifecycle automation |
| [operations-guide.md](operations-guide.md) | Operational procedures |
| [cost-control-checklist.md](cost-control-checklist.md) | Cost optimization checklist |
| [azure-setup.md](azure-setup.md) | Azure environment preparation |

---

## Architecture & Design

High-level architecture references.

| Document | Description |
|-----------|-------------|
| `/architecture` | Architecture diagrams |
| [org-overview.md](org-overview.md) | Project overview |
| [coreinfra-runbook.md](coreinfra-runbook.md) | Infrastructure runbook |

---

# Architecture Overview

Current implementation includes:

- Resource Groups
- Virtual Networks
- Subnets
- Network Security Groups
- Storage Accounts
- ADLS Gen2
- Azure Key Vault
- User Assigned Managed Identity
- Virtual Machines
- App Service Plans
- App Services
- Private Endpoint
- Private DNS
- Log Analytics Workspace
- Application Insights
- Diagnostic Settings
- Azure Monitor Alerts
- Recovery Services Vault
- Backup Policies
- VM Backup
- Disk Snapshots
- Azure RBAC
- GitHub Actions
- Azure OIDC Authentication

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

Deployment Validation

↓

Health Checks

↓

Deployment Summary

---

# Design Principles

The project follows enterprise engineering practices:

- Idempotent deployments
- Infrastructure as Code
- Modular architecture
- Enterprise naming standards
- Governance through tagging
- Security-first design
- Identity-based authentication
- Private networking
- Observability by default
- Documentation-driven implementation
- Repeatable deployment workflows

---

# Learning Objectives

This project was built to develop practical experience with:

- Azure Administration (AZ-104)
- Azure Infrastructure
- Infrastructure Automation
- PowerShell
- GitHub Actions
- Azure Security
- Azure Networking
- Azure Monitoring
- Managed Identity
- Private Endpoints
- Backup & Recovery
- Enterprise Cloud Operations

---

# Future Roadmap

Planned future enhancements include:

- Azure Policy
- Management Groups
- Azure Bastion
- Load Balancer
- Application Gateway
- Azure Front Door
- VPN Gateway
- ExpressRoute
- Terraform implementation
- Azure Kubernetes Service (AKS)
- SQL & PostgreSQL modules

---

# Project Status

**Current Release**

v1.0.0

**Status**

Active Development

**Repository**

cloud-org-infra
