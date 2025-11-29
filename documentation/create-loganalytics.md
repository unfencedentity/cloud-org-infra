# Log Analytics Workspace Provisioning Module (`create-loganalytics.ps1`)

## Overview

The **Log Analytics Workspace provisioning module** creates or reuses a Log Analytics Workspace (LAW) for a specific application, environment, and region. It is part of the observability and monitoring layer in the `cloud-org-infra` project and is designed to be:

- idempotent  
- consistent with the global naming and tagging conventions  
- safe for repeated use and CI/CD integration  
- explicit about pricing tier and retention settings

The module is located at:

`/automation/create-loganalytics.ps1`

It is typically executed by the main environment orchestrator (`deploy-environment.ps1`), not directly.

---

## Responsibilities

For each run, the module:

1. Validates that the **Resource Group** for the target environment exists.  
2. Ensures a **Log Analytics Workspace** exists for the given application, environment, and region.  
3. Aligns the **retention** of an existing workspace with the desired configuration.

This provides a consistent logging and telemetry backend that can be used by Application Insights, diagnostics, and alerting modules.

---

## Naming Convention

The module follows the same naming scheme used throughout the infrastructure:

- **Resource Group:** `rg-<app>-<environment>-<region>`
- **Log Analytics Workspace:** `law-<app>-<environment>-<region>`

Example for `app = billing`, `environment = dev`, `region = weu`:

- `rg-billing-dev-weu`
- `law-billing-dev-weu`

This makes it easy to identify which workspace belongs to which application environment.

---

## Tags

The workspace is created with a standard set of tags:

- `environment = <Environment>`
- `app         = <App>`
- `region      = <Region>`
- `owner       = cloud-org-infra`

These tags support governance, reporting, and cost allocation in larger environments.

---

## Parameters

The module accepts the following parameters:

### Required

- **Environment** (`string`)  
  Logical environment name (e.g. `dev`, `test`, `prod`). Used for naming and tagging.

- **App** (`string`)  
  Application identifier (e.g. `billing`, `portal`). Used for naming and tagging.

- **Region** (`string`)  
  Short region code aligned with the rest of the project (e.g. `weu`, `neu`). Used for naming.

- **Location** (`string`)  
  Azure location display name (e.g. `West Europe`, `North Europe`). Used when creating the workspace.

### Optional

- **WorkspaceSku** (`string`, default: `PerGB2018`)  
  Pricing tier for the Log Analytics Workspace.

- **RetentionInDays** (`int`, default: `30`)  
  Retention period for the workspace, in days. This can be tuned per environment.

---

## Behavior and Idempotency

1. The module first checks if the target **Resource Group** exists.  
   - If it does not exist, execution stops with an error instructing the user to run the Resource Group provisioning module first.

2. It then tries to retrieve an existing **Log Analytics Workspace** with the expected name in the target Resource Group.  
   - If the workspace exists, it is reused.  
   - If the current retention does not match `RetentionInDays`, the module updates the retention settings (wrapped in `ShouldProcess` for safety).

3. If the workspace does **not** exist, the module creates a new one using:
   - the requested SKU  
   - the requested retention  
   - the configured tags  

In all cases, the module returns the final workspace object.

---

## Safety and `ShouldProcess`

The module uses:

- `SupportsShouldProcess = $true`

This enables:

- `-WhatIf` to simulate changes without applying them.  
- `-Confirm` to request confirmation before making changes.

Workspace creation and retention updates are wrapped in `ShouldProcess`, making the module safe for both interactive and automated use.

---

## Execution Flow Summary

1. Validate input parameters.  
2. Build names using the standard naming convention.  
3. Validate that the Resource Group exists.  
4. Try to retrieve the existing workspace.  
5. If it exists:
   - reuse it
   - optionally update retention if needed.  
6. If it does not exist:
   - create a new workspace with the requested settings and tags.  
7. Return the resulting workspace object.

This ensures each environment has a well-defined, centrally managed Log Analytics Workspace that other modules (such as Application Insights and alerting) can depend on.
