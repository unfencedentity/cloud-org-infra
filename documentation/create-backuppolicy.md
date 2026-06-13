# Backup Policy Deployment

## Overview

This module deploys Azure Backup Policies used to define backup schedules, retention settings, and protection requirements for workloads protected by the Recovery Services Vault.

Backup Policies provide centralized and consistent backup management across the cloud-org-infra environment.

---

## Components

* Backup Policy
* Backup Schedule
* Retention Rules
* Protected Resources
* Recovery Services Vault

---

## Architecture

Virtual Machine
↓
Backup Policy
↓
Recovery Services Vault
↓
Recovery Point

---

## Purpose

Backup Policies define:

* When backups run
* How long backups are retained
* Which resources are protected
* Recovery requirements
* Compliance requirements

---

## Validation

The implementation was validated by:

* Deploying Backup Policy
* Verifying policy creation
* Associating policy with Virtual Machines
* Executing backup jobs
* Confirming recovery point generation
* Verifying retention configuration

---

## AZ-104 Topics

* Backup Policies
* Azure Backup
* Recovery Services Vault
* Recovery Points
* Backup Schedules
* Retention Policies
* Restore Operations

---

## Common Interview Topics

* What is a Backup Policy?
* Why use policy-based backups?
* Recovery Point vs Backup Policy
* Retention strategies
* Backup governance
* Compliance requirements

---

## Common Mistakes

* Creating a policy but not assigning it to resources
* Assuming backup starts automatically after policy creation
* Not validating recovery point generation
* Using retention settings that do not meet business requirements

---

## Simple Analogy

A Backup Policy is like a company rulebook that specifies when backups occur and how long backup copies must be kept before they can be removed.

---

## Key Takeaways

* Backup Policies define backup schedules and retention settings.
* Recovery Services Vault stores the resulting backup data.
* Protected resources inherit backup behavior from assigned policies.
* Policy-based backup management improves consistency and operational reliability.
