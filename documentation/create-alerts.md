# Alerts Provisioning Module (`create-alerts.ps1`)

## Overview

The **Alerts provisioning module** creates and maintains a standard set of Azure Monitor alerts for a given application, environment, and region.  
It focuses on:

- critical **App Service** metrics (CPU and HTTP 5xx errors)
- consistent **Action Group** management
- idempotent and automated alert creation

The module is located at:

`/automation/create-alerts.ps1`

It is intended to be executed by the main environment orchestrator (`deploy-environment.ps1`) as the final step of the deployment pipeline.

---

## Responsibilities

For each combination of `App`, `Environment`, and `Region`, the module:

1. Validates the **Resource Group** and the **App Service**.
2. Ensures an **Action Group** exists for that application environment.
3. Creates **metric-based alerts** for:
   - high CPU usage
   - HTTP 5xx spikes
4. Reuses existing alerts when they are already present (idempotent behavior).
5. Associates all alerts with the same Action Group.

This provides a baseline enterprise monitoring setup that can be extended with additional rules.

---

## Naming Convention

The module follows the global `cloud-org-infra` naming standards:

- **Resource Group:** `rg-<app>-<environment>-<region>`
- **App Service:** `app-<app>-<environment>-<region>`
- **Application Insights:** `appi-<app>-<environment>-<region>`
- **Action Group:** `ag-<app>-<environment>-<region>`
- **Alerts:**
  - `alert-app-<app>-<environment>-<region>-cpu-high`
  - `alert-app-<app>-<environment>-<region>-http5xx`

Example for `app = core`, `environment = dev`, `region = weu`:

- `rg-core-dev-weu`
- `app-core-dev-weu`
- `ag-core-dev-weu`
- `alert-app-core-dev-weu-cpu-high`
- `alert-app-core-dev-weu-http5xx`

---

## Tags

The module uses the standard tagging model where relevant (and for potential future extensions):

- `environment = <Environment>`
- `app         = <App>`
- `region      = <Region>`
- `owner       = cloud-org-infra`

---

## Parameters

### Required

- **Environment** (`string`)  
- **App** (`string`)  
- **Region** (`string`)  
- **Location** (`string`)

These ensure consistent naming and resource placement.

### Optional

- **AlertEmails** (`string[]`)  
  Email addresses to be added as receivers in the Action Group.  
  If no Action Group exists and no `AlertEmails` are provided, the module will skip alert creation.

- **CpuThreshold** (`int`, default: `80`)  
  CPU percentage threshold for the high-CPU alert.

- **CpuDurationMinutes** (`int`, default: `5`)  
  Evaluation window for the CPU alert.

- **Http5xxThreshold** (`int`, default: `10`)  
  Threshold for HTTP 5xx count in the selected time window.

- **Http5xxDurationMinutes** (`int`, default: `5`)  
  Evaluation window for the HTTP 5xx alert.

---

## Behavior and Idempotency

### Action Group Handling

- The module looks for an Action Group named:  
  `ag-<app>-<environment>-<region>` in the target Resource Group.
- If it exists, it is reused.
- If it does **not** exist:
  - and `AlertEmails` is provided → a new Action Group is created with email receivers.
  - and `AlertEmails` is **not** provided → a warning is emitted and alert creation is skipped.

### Alert Rules

The module defines two core metric alerts:

1. **CPU High Alert**
   - Metric: `CpuPercentage`
   - Condition: `Average > CpuThreshold`
   - Window: `CpuDurationMinutes`
   - Severity: `2`

2. **HTTP 5xx Alert**
   - Metric: `Http5xx`
   - Condition: `Total > Http5xxThreshold`
   - Window: `Http5xxDurationMinutes`
   - Severity: `3`

Before creating an alert, the module checks if an alert with the given name already exists:

- If it exists, the module logs that it is reusing the existing rule.
- If it does not exist, the rule is created and associated with the Action Group.

---

## Safety and `ShouldProcess`

The module is decorated with:

`[CmdletBinding(SupportsShouldProcess = $true)]`

This enables:

- `-WhatIf` to simulate changes.
- `-Confirm` to require user confirmation.

Action Group creation and alert creation are wrapped in `ShouldProcess` for safe usage in both interactive and automated contexts.

---

## Execution Flow Summary

1. Validate Resource Group and App Service.
2. Ensure or create the Action Group (`ag-<app>-<environment>-<region>`).
3. Create or reuse:
   - CPU high alert
   - HTTP 5xx alert
4. Return after configuring all rules.

This module is designed to be the final layer in the environment setup, providing a standardized alerting baseline for all deployed applications.
