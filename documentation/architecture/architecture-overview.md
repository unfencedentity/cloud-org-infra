# Cloud Org Architecture – Overview

This document provides a high-level overview of the cloud organization structure.  
It will later include identity layout, subscription model, governance baseline, and automation entry points.

Initial notes:
- Identity secured using Microsoft Entra ID.
- Resource organization aligned with subscription and management group structure.
- Automation tools: Azure DevOps / GitHub Actions (pending design).

## Purpose & Guiding Principles

This cloud organization architecture aims to provide a secure, scalable, and well-structured foundation for all environments within the company.  
It ensures consistency across deployments, reduces operational overhead, and enables controlled growth of cloud resources.

### Guiding Principles

- **Security First** — Identity, access, and network boundaries are defined before any workload is deployed.
- **Least Privilege** — All access follows RBAC and is granted only when required.
- **Modularity** — Infrastructure components are separated into reusable building blocks.
- **Automation by Default** — Deployments, configurations, and updates are expected to be driven by IaC pipelines.
- **Cost Transparency** — Resources are organized to support clear cost reporting and governance.