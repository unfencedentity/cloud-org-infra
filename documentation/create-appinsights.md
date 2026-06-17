# Application Insights Provisioning Module (`create-appinsights.ps1`)

## Overview

The **Application Insights provisioning module** creates or updates an Application Insights resource for a specific application, environment, and region.  
It is designed to:

- be idempotent  
- enforce enterprise naming and tagging conventions  
- link the Application Insights instance to the correct Log Analytics Workspace  
- integrate cleanly with the main orchestrator (`deploy-environment.ps1`)  
- prepare the telemetry layer required by App Service and observability tooling

The module is located at:

`/automation/create-appinsights.ps1`

It is normally executed automatically by the orchestrator, not manually.

---

## Responsibilities

The module performs the following responsibilities:

1. Validates that the **Resource Group** for the target environment exists.  
2. Validates that the required **Log Analytics Workspace** exists.  
3. Ensures that an Application Insights instance exists for the given application/environment/region.  
4. If the AI instance already exists:
   - it is reused  
   - the Workspace link is validated and corrected if necessary  
5. If the AI instance does not exist:
   - a new one is created  
   - it is linked to the correct Log Analytics Workspace  
   - tags and naming conventions are applied  

This module is a core part of the enterprise observability stack.

---

## Naming Convention

The naming follows the global cloud-org-infra standard:

- **Resource Group:** `rg-<app>-<environment>-<region>`
- **Log Analytics Workspace:** `law-<app>-<environment>-<region>`
- **Application Insights:** `appi-<app>-<environment>-<region>`
- rg-core-dev-weu
law-core-dev-weu
appi-core-dev-weu

This ensures perfect alignment across telemetry, networking, applications, and automation.

---

## Tags

All resources provisioned by this module apply the standard tagging model:

- `environment = <Environment>`
- `app         = <App>`
- `region      = <Region>`
- `owner       = cloud-org-infra`

These tags support governance, automation, cost allocation and resource tracking.

---

## Parameters

The module supports the following parameters:

### Required

- **Environment** (`string`)  
- **App** (`string`)  
- **Region** (`string`)  
- **Location** (`string`)  

These determine naming, placement and workload identification.

### Optional

- **ApplicationType** (`string`, default: `web`)  
- **Kind** (`string`, default: `web`)  

These values align with web workload defaults, but can be extended in the future.

---

## Behavior & Idempotency

The module is fully idempotent:

1. If Application Insights exists:
   - it is returned  
   - the workspace link is validated  
   - if the workspace does not match → the resource is updated  

2. If Application Insights does NOT exist:
   - a new AI resource is created  
   - it is linked to the correct Log Analytics Workspace  
   - tags are applied  

All create/update operations are wrapped in:

- `SupportsShouldProcess`  
- `-WhatIf` / `-Confirm` friendly behavior  

This ensures safe use inside CI/CD pipelines.

---

## Dependency Requirements

This module depends on the presence of:

- Resource Group module (`create-rg.ps1`)
- Log Analytics Workspace module (`create-loganalytics.ps1`)

Both must be executed before calling this module.

---

## Execution Flow Summary

1. Validate the Resource Group  
2. Validate the Log Analytics Workspace  
3. Attempt to retrieve an existing Application Insights resource  
4. If found:
   - validate Workspace linkage  
   - correct it if necessary  
5. If not found:
   - create new Application Insights instance  
   - link to LAW  
   - apply tags  
6. Return the created or updated instance  

This enables a fully automated, standardized, enterprise-grade observability layer.

---


Example:

## Usage Example

### Basic execution

```powershell
.\create-appinsights.ps1 `
    -Environment dev `
    -App core `
    -Region weu `
    -Location westeurope
```

### Example Result

Application Insights:

appi-core-dev-weu

Connected Log Analytics Workspace:

law-core-dev-weu

Resource Group:

rg-core-dev-weu

```md
---

## Validation

The implementation was validated by:

- Creating a new Application Insights resource
- Linking Application Insights to Log Analytics Workspace
- Verifying telemetry ingestion
- Verifying Workspace-based configuration
- Executing repeated deployments to confirm idempotency
- Confirming correct tag application

---

## AZ-104 Topics

- Azure Monitor
- Application Insights
- Log Analytics Workspace
- Telemetry
- Monitoring
- Metrics
- Logs
- Observability

---

## Common Interview Topics

- What is Application Insights?
- Application Insights vs Log Analytics
- Workspace-based Application Insights
- What telemetry does Application Insights collect?
- How Application Insights integrates with App Service
- Why centralize telemetry in Log Analytics?

---

## Common Mistakes

- Creating standalone Application Insights instances without Log Analytics integration
- Not centralizing telemetry
- Missing retention and monitoring strategy
- Confusing Application Insights with Log Analytics
- Not monitoring application performance and failures

---

## Simple Analogy

Application Insights is like a health monitoring system for an application.

While infrastructure monitoring tells you whether servers and resources are healthy, Application Insights tells you whether the application itself is healthy, how users interact with it, where errors occur, and how quickly requests are processed.

---

## Key Takeaways

- Application Insights provides application-level monitoring and telemetry.
- Workspace-based Application Insights centralizes observability in Log Analytics.
- The module automatically creates or validates telemetry resources.
- Idempotent execution makes the module safe for CI/CD and repeated deployments.
- Application Insights is a core component of enterprise monitoring architectures.

