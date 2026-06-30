# Virtual Machine Deployment

## Overview

This module deploys Azure Virtual Machines used for infrastructure validation, operational testing, backup verification, monitoring integration, and platform administration scenarios within the cloud-org-infra environment.

The deployment follows enterprise naming standards, integrates with the existing virtual network architecture, and serves as the primary workload used for backup, recovery, diagnostics, and monitoring validation.

---

## Components

- Azure Virtual Machine
- Managed Disk
- Network Interface
- Virtual Network Integration
- Network Security Group Protection
- Backup Integration
- Log Analytics Integration

---

## Architecture

Virtual Machine → Network Interface → Subnet → Virtual Network

Virtual Machine → Managed Disk

Virtual Machine → Recovery Services Vault

Virtual Machine → Log Analytics Workspace

---

## Purpose

The Virtual Machine layer provides compute resources used for:

- Infrastructure validation
- Backup and recovery testing
- Monitoring validation
- Network connectivity testing
- Administrative operations
- Platform demonstrations

---

## Validation

The implementation was validated by:

- Deploying Linux Virtual Machines
- Verifying VNet connectivity
- Verifying NIC association
- Verifying managed disk creation
- Validating backup integration
- Validating snapshot creation
- Validating diagnostics configuration

---

## AZ-104 Topics

- Azure Virtual Machines
- Managed Disks
- Availability Options
- VM Networking
- VM Backup
- Snapshots
- Extensions
- Monitoring
- Virtual Machine Scale Concepts

---

## Common Interview Topics

- Difference between VM and App Service
- Managed Disk types
- Snapshot vs Backup
- Availability Set vs Availability Zone
- VM networking components
- VM monitoring and diagnostics
- Backup and recovery strategies

---

## Key Takeaways

- Azure Virtual Machines provide Infrastructure-as-a-Service (IaaS) compute resources.
- VMs are commonly used when full operating system control is required.
- Virtual Machines integrate with networking, monitoring, backup, and security services across Azure.
