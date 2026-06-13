# Recovery Services Vault Deployment

## Overview

This module deploys an Azure Recovery Services Vault used to provide centralized backup and recovery capabilities for cloud-org-infra resources.

The Recovery Services Vault serves as the foundation for Azure Backup and enables policy-based protection, recovery point management, and restore operations.

---

## Components

- Recovery Services Vault
- Backup Policies
- Protected Virtual Machines
- Recovery Points
- Backup Jobs

---

## Architecture

Virtual Machine
↓
Backup Policy
↓
Recovery Services Vault
↓
Recovery Point

Restore Operations
↓
Recovery Services Vault
↓
Virtual Machine

---

## Purpose

The Recovery Services Vault provides:

- Centralized backup management
- Long-term backup retention
- Recovery point storage
- Restore capabilities
- Operational resilience
- Disaster recovery support

---

## Validation

The implementation was validated by:

- Deploying Recovery Services Vault
- Verifying vault creation
- Associating backup policies
- Enabling VM backup protection
- Executing on-demand backup jobs
- Verifying recovery point creation
- Confirming successful backup status

---

## AZ-104 Topics

- Recovery Services Vault
- Azure Backup
- Backup Policies
- Recovery Points
- Backup Jobs
- Restore Operations
- Business Continuity
- Disaster Recovery

---

## Common Interview Topics

- What is a Recovery Services Vault?
- Backup vs Snapshot
- Recovery Point vs Backup Job
- Policy-based backup management
- Long-term retention strategies
- Restore workflows
- Business continuity planning

---

## Common Mistakes

- Assuming a backup policy automatically protects resources
- Forgetting to enable backup protection on Virtual Machines
- Not validating recovery point creation
- Confusing snapshots with Azure Backup

---

## Simple Analogy

A Recovery Services Vault is like a secure off-site archive where backup copies are stored and managed. If a system is lost, damaged, or deleted, the vault provides the information required to restore it.

---

## Key Takeaways

- Recovery Services Vault is the central Azure Backup service.
- Backup policies define protection schedules and retention settings.
- Recovery points provide restore options for protected workloads.
- Recovery Services Vault enables operational recovery and disaster recovery scenarios.
