# Extended App Service Configuration Module (`create-appservice-extended.ps1`)

## Overview

The **Extended App Service Configuration module** applies enterprise-grade settings to an existing Azure App Service instance.  
It is executed after the following modules:

1. `create-appservice.ps1` — creates the App Service
2. `create-appinsights.ps1` — provisions Application Insights
3. `create-loganalytics.ps1` — provisions Log Analytics Workspace

This module enforces organizational standards for security, observability, and operational readiness.

It is located at:

`/automation/create-appservice-extended.ps1`

---

## Responsibilities

The module performs:

### **1. Application Insights Integration**
Automatically sets:
- `APPINSIGHTS_INSTRUMENTATIONKEY`
- `APPLICATIONINSIGHTS_CONNECTION_STRING`

This ensures the App Service sends telemetry correctly.

---

### **2. Enforce Enterprise Security Settings**
- Enables **HTTPS Only**
- Sets **Minimum TLS Version** (1.2 by default)

These settings align with modern enterprise compliance requirements.

---

### **3. Enable Managed Identity**
Activates System Assigned Identity, enabling secure authentication to Azure services (Key Vault, Storage, etc.) without secrets.

---

### **4. Enable Always On**
Ensures the app stays warm and avoids cold starts—important for production workloads.

---

### **5. Diagnostic Logging to Log Analytics**
Enables:
- Application logs  
- Web server logs  
- Metrics  

All sent to the Log Analytics Workspace defined for the application.

---

## Naming Convention

Aligned with the global project standard:

| Resource | Pattern |
|---------|---------|
| App Service | `app-<app>-<environment>-<region>` |
| App Insights | `appi-<app>-<environment>-<region>` |
| LAW | `law-<app>-<environment>-<region>` |

Example:  
`app-core-dev-weu`

---

## Parameters

### Required
- **Environment**  
- **App**  
- **Region**  
- **Location**

### Optional (Default Enterprise Settings)
- `EnableHTTPSOnly = true`
- `MinimumTLSVersion = "1.2"`
- `EnableIdentity = true`
- `EnableAlwaysOn = true`

Defaults chosen to satisfy enterprise compliance requirements.

---

## Idempotency & Safety

The module:

- Reuses existing resources  
- Updates only what is misconfigured  
- Wraps all changes inside `ShouldProcess`  
- Supports `-WhatIf` and `-Confirm` operations  

This makes it safe for CI/CD pipelines and repeatable deployments.

---

## Execution Flow

1. Validates that the App Service exists  
2. Validates that Application Insights exists  
3. Updates App Settings with AI keys  
4. Enforces HTTPS only, TLS min version  
5. Enables Managed Identity  
6. Configures Always On  
7. Enables diagnostic logs to LAW  
8. Returns final Web App state  

---

## Purpose in the Architecture

This module transforms a basic App Service into an **enterprise-ready workload** by applying:

- security  
- monitoring  
- logging  
- reliability  
- operational standards  

It is a mandatory component of the cloud-org-infra baseline environment.
