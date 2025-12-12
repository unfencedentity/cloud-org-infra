# Linux Scope in cloud-org-infra

## Purpose

This document clarifies how Linux is used and abstracted within the cloud-org-infra platform.

The goal is to define **responsibilities**, **boundaries**, and **intentional abstractions** rather than low-level OS administration.

---

## How Linux is used in this platform

Linux is treated as the **execution layer**, not as a manually managed system.

All application workloads run on:
- Azure App Services (Linux-based)
- Managed Azure services backed by Linux

The platform does **not** rely on:
- Manual SSH access
- Direct OS patching
- Low-level system configuration

---

## What is intentionally abstracted

The following Linux responsibilities are handled by Azure-managed services:

- OS patching and updates
- Kernel and system security
- Service availability and uptime
- Base image maintenance

This allows the platform to focus on **application delivery and reliability**, not server maintenance.

---

## What the platform owner controls

The platform defines and controls:

- Network boundaries (VNet, subnets, NSGs)
- Identity and access (Managed Identity, RBAC)
- Security posture (Key Vault, TLS, HTTPS-only)
- Observability (Log Analytics, Application Insights)
- Diagnostics and monitoring pipelines

---

## Why this approach

This design follows modern cloud-native principles:

- Platform over servers
- Automation over manual intervention
- Security and observability by default
- Repeatable, idempotent deployments

The result is a **Linux-aware platform**, not a traditional Linux administration model.

---

## Summary

cloud-org-infra uses Linux as a stable, managed foundation while focusing engineering effort on:
- automation
- security
- observability
- scalability

This reflects real-world enterprise cloud environments.