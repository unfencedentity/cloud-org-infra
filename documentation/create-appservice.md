# App Service Provisioning Module (`create-appservice.ps1`)

## Overview
The App Service provisioning module creates or reuses an Azure App Service Plan and a Web App for a specific application, environment, and region. It follows the enterprise automation patterns used across the `cloud-org-infra` project, providing predictable, idempotent, and orchestrated infrastructure deployment.

This module is located at:
`/automation/create-appservice.ps1`

It is normally executed via the environment orchestrator (`deploy-environment.ps1`) rather than manually.

---

## Responsibilities

### 1. Resource Group Validation
The module verifies that the target Resource Group exists.  
If it is missing, execution stops and instructs the user to run `create-rg.ps1` first.  
This ensures App Service resources are only created inside a structured environment.

---

### 2. App Service Plan Creation or Reuse
The module checks if the App Service Plan already exists.

- If it exists, the plan is reused.
- If it does not exist, the module creates a new App Service Plan using:
  - the specified SKU (default: B1)
  - the Azure region (`Location`)
  - one worker
  - standardized naming

This guarantees predictable, repeatable structure across all environments.

---

### 3. Web App Creation or Reuse
After ensuring the App Service Plan exists, the module checks whether the Web App already exists.

- If it exists, it is reused and returned.
- If it does not exist, a new Web App is created and associated with the App Service Plan.

The module returns the Web App object at the end of execution.

---

## Naming Convention
The module follows the naming rules used throughout the infrastructure:

- **Resource Group:** `rg-<app>-<environment>-<region>`
- **App Service Plan:** `asp-<app>-<environment>-<region>`
- **Web App:** `app-<app>-<environment>-<region>`

Example (`app=billing`, `env=dev`, `region=weu`):
- `rg-billing-dev-weu`
- `asp-billing-dev-weu`
- `app-billing-dev-weu`

This ensures clarity and consistency in multi-application and multi-environment setups.

---

## Tags
The module defines a standard set of governance and ownership tags:
environment = <environment>
app = <app>
region = <region>
owner = cloud-org-infra


Tag propagation will be extended in a future iteration.

---

## Parameters

### Required
- **Environment** – environment identifier (`dev`, `test`, `prod`)
- **App** – application identifier
- **Region** – short regional code used in naming (`weu`, `neu`, etc.)
- **Location** – Azure location (`West Europe`, `North Europe`, etc.)

### Optional
- **AppServicePlanSku** – default: `B1`
- **RuntimeStack** – `Windows` or `Linux` (default: `Windows`)

These parameters make the module flexible for future runtime and SKU expansions.

---

## Idempotency & Safety
The module uses:

- `SupportsShouldProcess = $true`
- `WhatIf`
- `Confirm`

This allows safe repeated execution.  
Existing resources are never duplicated or overwritten unless explicitly confirmed.

---

## Execution Flow Summary
1. Validate parameters  
2. Construct names using standardized patterns  
3. Validate existence of the Resource Group  
4. Create or reuse the App Service Plan  
5. Create or reuse the Web App  
6. Return the Web App object  

This provides consistent and deterministic infrastructure provisioning across all environments.

---

## Notes
This documentation describes the behavior of the script located at `/automation/create-appservice.ps1`, which includes the full provisioning logic for App Service Plans and Web Apps.


