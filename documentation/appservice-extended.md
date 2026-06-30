# Extended App Service Configuration Module (create-appservice-extended.ps1)

## Overview

The Extended App Service Configuration module applies enterprise-grade configuration settings to an existing Azure App Service instance.

It is executed after the following modules:

1. create-appservice.ps1
2. create-appinsights.ps1
3. create-loganalytics.ps1

The module enforces security, monitoring, observability, and operational standards used in enterprise Azure environments.

Location:

```text
/automation/create-appservice-extended.ps1
```

---

## Purpose

The module transforms a basic App Service deployment into a production-ready workload by applying:

- Security controls
- Monitoring integration
- Telemetry configuration
- Identity management
- Operational readiness settings
- Enterprise compliance standards

This module represents the final application hardening and observability layer.

---

## Features

- Application Insights integration
- Log Analytics integration
- HTTPS enforcement
- TLS hardening
- Managed Identity enablement
- Always On configuration
- Diagnostic logging configuration
- Idempotent execution
- CI/CD friendly deployment
- Enterprise baseline configuration

---

## Responsibilities

### Application Insights Integration

Automatically configures:

- APPINSIGHTS_INSTRUMENTATIONKEY
- APPLICATIONINSIGHTS_CONNECTION_STRING

This ensures application telemetry is forwarded correctly.

---

### Enterprise Security Configuration

Applies:

- HTTPS Only
- Minimum TLS Version

Default:

```text
TLS 1.2
```

These settings align with modern security requirements and compliance standards.

---

### Managed Identity Enablement

Enables:

```text
System Assigned Managed Identity
```

Benefits:

- No stored credentials
- Secure Azure authentication
- Key Vault integration
- Storage Account integration
- Secretless application design

---

### Always On Configuration

Enables:

```text
Always On
```

Benefits:

- Reduced cold starts
- Improved responsiveness
- Better production readiness
- Improved application availability

---

### Diagnostic Logging

Configures:

- Application Logs
- Web Server Logs
- Metrics

Destination:

```text
law-<app>-<environment>-<region>
```

This enables centralized monitoring and troubleshooting.

---

## Naming Convention

The module follows the cloud-org-infra naming standard.

| Resource | Pattern |
|-----------|-----------|
| App Service | `app-<app>-<environment>-<region>` |
| App Insights | `appi-<app>-<environment>-<region>` |
| Log Analytics Workspace | `law-<app>-<environment>-<region>` |

Example:

```text
app-core-dev-weu
appi-core-dev-weu
law-core-dev-weu
```

---

## Parameters

### Required

- Environment
- App
- Region
- Location

### Optional

| Parameter | Default |
|------------|------------|
| EnableHTTPSOnly | true |
| MinimumTLSVersion | 1.2 |
| EnableIdentity | true |
| EnableAlwaysOn | true |

These defaults represent the enterprise baseline configuration.

---

## Dependency Requirements

The following resources must already exist:

- Resource Group
- App Service
- Application Insights
- Log Analytics Workspace

Required modules:

- create-rg.ps1
- create-appservice.ps1
- create-appinsights.ps1
- create-loganalytics.ps1

---

## Behavior and Idempotency

The module follows an idempotent deployment model.

If configuration already exists:

- Existing settings are preserved
- No duplicate configuration is applied

If configuration differs:

- Drift is corrected
- Required settings are enforced

All operations support:

- ShouldProcess
- WhatIf
- Confirm

This makes the module safe for:

- CI/CD pipelines
- Repeated deployments
- Infrastructure validation
- Compliance audits
- Environment rebuilds

---

## Execution Flow

The module performs the following steps:

1. Validate App Service existence
2. Validate Application Insights existence
3. Validate Log Analytics Workspace existence
4. Configure Application Insights integration
5. Enable HTTPS Only
6. Configure Minimum TLS Version
7. Enable Managed Identity
8. Configure Always On
9. Configure diagnostic logging
10. Return final App Service state

---

## Return Value

The module returns the updated App Service object.

Possible outcomes:

- Existing App Service with validated configuration
- Existing App Service with remediated configuration

This allows downstream automation to consume the final workload state.

---

## Validation

The implementation was validated by:

- Configuring Application Insights integration
- Verifying telemetry flow
- Verifying Managed Identity creation
- Verifying HTTPS enforcement
- Verifying TLS configuration
- Verifying diagnostic logging
- Executing repeated deployments
- Confirming idempotent behavior

---

## AZ-104 Topics

- Azure App Service
- Managed Identity
- Application Insights
- Log Analytics Workspace
- Diagnostic Settings
- TLS
- HTTPS Only
- Azure Monitor
- Application Settings
- PaaS Security

---

## Common Interview Topics

- What is Managed Identity?
- Why use HTTPS Only?
- What is TLS hardening?
- Application Insights integration
- App Service security best practices
- App Service monitoring architecture
- App Service production readiness
- Secretless authentication

---

## Common Mistakes

- Leaving applications accessible over HTTP
- Using outdated TLS versions
- Storing credentials inside applications
- Missing monitoring integration
- Ignoring application telemetry
- Deploying production workloads without Always On
- Not enabling Managed Identity

---

## Simple Analogy

The App Service module builds the car.

The Extended App Service module installs the seatbelts, airbags, dashboard, GPS, and monitoring systems.

The application can run without these features, but it is not production-ready.

---

## Key Takeaways

- This module converts a basic App Service into an enterprise-ready workload.
- Managed Identity eliminates the need for stored credentials.
- Application Insights and Log Analytics provide centralized observability.
- HTTPS and TLS settings improve security posture.
- The module supports repeatable and idempotent enterprise deployments.
