# Diagnostics Module (create-diagnostics.ps1)

This module configures Azure Diagnostic Settings for supported resources and routes logs and metrics to a centralized Log Analytics Workspace (LAW).

It is designed to be:

- Idempotent
- Environment-agnostic
- Naming-driven
- Governance-aligned
- Suitable for CI/CD automation

---

## Purpose

The module automatically discovers supported Azure resources and configures Diagnostic Settings using a standardized approach.

Its primary goals are:

- Centralized logging
- Centralized metrics collection
- Consistent monitoring configuration
- Reduced operational overhead
- Improved security visibility
- Governance and compliance readiness

All logs and metrics are routed to a central Log Analytics Workspace.

---

## Features

- Automatic resource discovery
- Centralized Log Analytics integration
- AllLogs and AllMetrics support
- Idempotent execution
- Standardized naming conventions
- CI/CD friendly
- Multi-environment support
- Multi-region support
- Governance-aligned monitoring

---

## Naming Convention

Diagnostic Settings follow the pattern:

diag-<resource-name>

Examples:

diag-vnet-core-dev-weu

diag-nsg-core-dev-weu

diag-kv-core-dev-weu

diag-app-core-dev-weu

The destination Log Analytics Workspace follows:

law-<app>-<environment>-<region>

Example:

law-core-dev-weu

---

## Automatic Resource Discovery

The module dynamically discovers Azure resources using naming conventions and resource metadata.

Examples:

Log Analytics Workspace:

law-<app>-<environment>-<region>

Key Vault:

kv-<app>-<environment>-<region>

Storage Accounts:

Tags:

app=<App>

environment=<Environment>

This removes hardcoded resource references and enables reusable deployments across environments and regions.

---

## Diagnostic Categories

The module uses Azure Category Groups whenever supported.

Configured categories:

- AllLogs
- AllMetrics

Benefits:

- Complete observability
- Reduced maintenance
- Automatic support for newly added Azure diagnostic categories
- SIEM compatibility
- Standardized monitoring across services

---

## Supported Resource Types

The module currently supports:

- Virtual Networks (VNets)
- Network Security Groups (NSGs)
- Storage Accounts
- Key Vaults
- App Service Plans
- App Services

Destination:

- Log Analytics Workspace (LAW)

Application Insights is not configured as a target because telemetry is collected natively.

---

## Planned Future Support

Future enhancements may include:

- Virtual Machines
- Azure SQL
- Cosmos DB
- API Management
- Event Hubs
- Long-term archival storage
- Additional platform services

---

## Usage Example

```powershell
.\create-diagnostics.ps1 `
    -Environment dev `
    -App core `
    -Region weu `
    -Location westeurope
```

---

## Operational Flow

The module performs the following steps:

1. Load deployment parameters
2. Locate the target Log Analytics Workspace
3. Discover supported Azure resources
4. Generate standardized diagnostic setting names
5. Check for existing diagnostic settings
6. Create missing diagnostic settings
7. Route logs and metrics to Log Analytics
8. Return deployment status

---

## Idempotency Behavior

Before creating a Diagnostic Setting, the module checks whether it already exists.

If the setting exists:

- No changes are made
- The resource is skipped

If the setting does not exist:

- A new Diagnostic Setting is created

This allows safe execution during:

- CI/CD deployments
- Infrastructure updates
- Repeated deployments
- Environment rebuilds
- Multi-region rollouts

---

## Return Value

The module returns deployment status information for each processed resource.

Information includes:

- Resource name
- Resource type
- Diagnostic setting status
- Creation result
- Skip result

---

## Validation

The implementation was validated by:

- Creating Diagnostic Settings for supported resources
- Verifying Log Analytics ingestion
- Verifying metrics collection
- Verifying repeated deployments
- Confirming idempotent behavior
- Confirming centralized logging functionality

---

## AZ-104 Topics

- Azure Monitor
- Diagnostic Settings
- Log Analytics Workspace
- Metrics
- Logs
- Monitoring
- Resource Health
- Governance

---

## Common Interview Topics

- What are Diagnostic Settings?
- Difference between Metrics and Logs
- Why use Log Analytics?
- How Diagnostic Settings integrate with Azure Monitor
- Why centralized monitoring matters
- Governance and compliance use cases

---

## Common Mistakes

- Not enabling Diagnostic Settings
- Storing logs in multiple destinations without strategy
- Missing critical audit logs
- Inconsistent monitoring across environments
- No centralized Log Analytics Workspace
- Assuming Azure services automatically send logs

---

## Simple Analogy

Diagnostic Settings are similar to security cameras installed throughout a building.

Each Azure resource generates events and activity.

Diagnostic Settings collect those events and send them to a central monitoring room (Log Analytics Workspace) where administrators can search, analyze, alert, and investigate issues.

---

## Why It Matters

This module provides:

- Centralized monitoring
- Improved troubleshooting
- Better security visibility
- Compliance readiness
- Operational consistency
- Enterprise-scale observability

It establishes the monitoring foundation required for production-ready Azure environments.
