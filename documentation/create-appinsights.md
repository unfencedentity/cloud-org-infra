# Application Insights Module (create-appinsights.ps1)

This module creates or validates an Azure Application Insights instance using standardized naming conventions, tagging policies, and Log Analytics Workspace integration.

It is designed to be idempotent and safe to execute multiple times.

---

## Purpose

The module provides a centralized and standardized telemetry platform for Azure workloads.

Its primary goals are:

* Application performance monitoring
* Centralized telemetry collection
* Integration with Log Analytics Workspace
* Enterprise observability
* Operational troubleshooting
* Consistent governance and naming standards

Application Insights acts as the application-level monitoring layer within the cloud-org-infra observability stack.

---

## Features

* Creates or reuses Application Insights resources
* Workspace-based Application Insights
* Automatic Log Analytics Workspace integration
* Standardized naming convention
* Standardized tagging
* Idempotent execution
* CI/CD friendly
* Multi-environment support
* Multi-region support
* Safe for repeated deployments

---

## Naming Convention

Application Insights names follow the pattern:

appi-<app>-<environment>-<region>

Example:

appi-core-dev-weu

The associated resources follow:

Resource Group:

rg-<app>-<environment>-<region>

Example:

rg-core-dev-weu

Log Analytics Workspace:

law-<app>-<environment>-<region>

Example:

law-core-dev-weu

This ensures alignment across networking, monitoring, compute, and automation layers.

---

## Parameters

| Name            | Type   | Required | Description                              |
| --------------- | ------ | -------- | ---------------------------------------- |
| Environment     | string | Yes      | Deployment environment (dev, test, prod) |
| App             | string | Yes      | Application identifier                   |
| Region          | string | Yes      | Region short-code (weu, neu, eus)        |
| Location        | string | Yes      | Azure location                           |
| ApplicationType | string | No       | Application type (default: web)          |
| Kind            | string | No       | Resource kind (default: web)             |

---

## Default Tags

The module applies the following standard tags:

environment = <Environment>

app = <App>

region = <Region>

owner = cloud-org-infra

Additional governance tags may be added through future enhancements.

---

## Dependency Requirements

The module requires the following resources to exist:

* Resource Group
* Log Analytics Workspace

Required modules:

* create-rg.ps1
* create-loganalytics.ps1

These modules should be executed before Application Insights provisioning.

---

## Behavior and Idempotency

The module follows a fully idempotent deployment model.

If Application Insights already exists:

* Existing resource is reused
* Workspace linkage is validated
* Configuration drift is corrected when required

If Application Insights does not exist:

* A new instance is created
* Log Analytics integration is configured
* Tags are applied

This behavior allows safe execution during:

* CI/CD deployments
* Infrastructure updates
* Environment rebuilds
* Multi-region rollouts
* Repeated automation runs

---

## Log Analytics Integration

Application Insights is deployed using the workspace-based model.

Benefits:

* Centralized telemetry storage
* Unified monitoring experience
* Simplified querying
* Improved governance
* Reduced operational complexity
* Better integration with Azure Monitor

All telemetry is linked to:

law-<app>-<environment>-<region>

---

## Usage Example

### Basic Execution

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

---

## Execution Flow

The module performs the following steps:

1. Validate Resource Group existence
2. Validate Log Analytics Workspace existence
3. Search for existing Application Insights resource
4. Validate workspace linkage
5. Create resource if missing
6. Apply standard tags
7. Return final resource object

---

## Return Value

The module returns the Application Insights object.

Possible outcomes:

* Existing Application Insights resource
* Newly created Application Insights resource

This enables downstream modules to consume telemetry configuration information.

---

## Validation

The implementation was validated by:

* Creating Application Insights resources
* Verifying workspace-based deployment
* Verifying Log Analytics integration
* Verifying telemetry ingestion
* Executing repeated deployments
* Confirming idempotent behavior
* Confirming tag application

---

## AZ-104 Topics

* Azure Monitor
* Application Insights
* Log Analytics Workspace
* Monitoring
* Telemetry
* Metrics
* Logs
* Observability

---

## Common Interview Topics

* What is Application Insights?
* Application Insights vs Log Analytics
* Workspace-based Application Insights
* What telemetry does Application Insights collect?
* How Application Insights integrates with App Service
* Why centralized telemetry matters
* Azure Monitor architecture

---

## Common Mistakes

* Deploying standalone Application Insights resources
* Not linking Application Insights to Log Analytics
* Missing telemetry retention strategy
* Inconsistent monitoring across environments
* Assuming infrastructure logs are sufficient
* Ignoring application-level monitoring

---

## Simple Analogy

Application Insights is similar to a health monitoring system for an application.

Infrastructure monitoring tells you whether servers and services are running.

Application Insights tells you:

* How users interact with the application
* Which requests fail
* Which dependencies are slow
* Where exceptions occur
* How the application performs over time

---

## Key Takeaways

* Application Insights provides application-level observability.
* Workspace-based deployment centralizes telemetry management.
* Integration with Log Analytics improves monitoring and governance.
* The module supports safe, repeatable, automated deployments.
* Application Insights is a core component of enterprise monitoring architectures.
