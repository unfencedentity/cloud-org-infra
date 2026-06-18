# App Service Module (create-appservice.ps1)

This module creates or validates an Azure App Service Plan and Web App using standardized naming conventions, tagging policies, and idempotent deployment behavior.

It is designed to provide a repeatable foundation for hosting web applications in the cloud-org-infra environment.

---

## Purpose

The module provisions the core Azure App Service resources required to host web workloads.

Its primary goals are:

- Web application hosting
- Standardized App Service Plan deployment
- Standardized Web App deployment
- Repeatable infrastructure provisioning
- CI/CD-friendly automation
- Consistent naming and governance
- Safe repeated execution

---

## Features

- Creates or reuses an App Service Plan
- Creates or reuses a Web App
- Uses standardized naming conventions
- Supports configurable SKU
- Supports Windows or Linux runtime configuration
- Applies governance tags
- Supports idempotent execution
- Supports WhatIf and Confirm behavior
- Integrates with the main deployment orchestrator

---

## Naming Convention

The module follows the global cloud-org-infra naming standard.

Resource Group:

```text
rg-<app>-<environment>-<region>
```

Example:

```text
rg-core-dev-weu
```

App Service Plan:

```text
asp-<app>-<environment>-<region>
```

Example:

```text
asp-core-dev-weu
```

Web App:

```text
app-<app>-<environment>-<region>
```

Example:

```text
app-core-dev-weu
```

This ensures predictable naming across applications, environments, regions, and automation workflows.

---

## Parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| Environment | string | Yes | Deployment environment such as dev, test, or prod |
| App | string | Yes | Application identifier |
| Region | string | Yes | Region short-code such as weu or neu |
| Location | string | Yes | Azure location such as westeurope |
| AppServicePlanSku | string | No | App Service Plan SKU, default B1 |
| RuntimeStack | string | No | Runtime platform, Windows or Linux |

---

## Default Tags

The module applies the following standard tags:

```text
environment = <Environment>
app         = <App>
region      = <Region>
owner       = cloud-org-infra
```

These tags support governance, cost allocation, ownership tracking, and environment visibility.

---

## Dependency Requirements

The module requires the target Resource Group to exist before execution.

Required module:

- create-rg.ps1

The module is normally executed by:

- deploy-environment.ps1

Manual execution is possible, but the orchestrator is preferred for full environment deployment.

---

## Behavior and Idempotency

The module follows an idempotent deployment model.

If the App Service Plan already exists:

- Existing plan is reused
- No duplicate plan is created

If the App Service Plan does not exist:

- A new plan is created
- SKU and location are applied
- Naming convention is enforced

If the Web App already exists:

- Existing Web App is reused
- No duplicate Web App is created

If the Web App does not exist:

- A new Web App is created
- It is associated with the App Service Plan

This makes the module safe for:

- CI/CD pipelines
- Repeated deployments
- Environment rebuilds
- Infrastructure validation
- Development and testing workflows

---

## App Service Plan

The App Service Plan provides the compute resources used by the Web App.

It defines:

- Pricing tier
- Compute capacity
- Scaling boundaries
- Operating system platform
- Regional placement

Multiple Web Apps can share the same App Service Plan when appropriate.

---

## Web App

The Web App is the application hosting resource.

It provides:

- Managed web hosting
- Platform-managed infrastructure
- Built-in scaling options
- Application deployment target
- Integration with monitoring and identity features

---

## Usage Example

### Basic Execution

```powershell
.\create-appservice.ps1 `
    -Environment dev `
    -App core `
    -Region weu `
    -Location westeurope
```

---

## Example Result

Resource Group:

```text
rg-core-dev-weu
```

App Service Plan:

```text
asp-core-dev-weu
```

Web App:

```text
app-core-dev-weu
```

---

## Execution Flow

The module performs the following steps:

1. Validate input parameters
2. Build standardized resource names
3. Validate Resource Group existence
4. Check for existing App Service Plan
5. Create App Service Plan if missing
6. Check for existing Web App
7. Create Web App if missing
8. Return the Web App object

---

## Return Value

The module returns the Web App object.

Possible outcomes:

- Existing Web App resource
- Newly created Web App resource

This allows downstream modules to consume the Web App configuration.

---

## Validation

The implementation was validated by:

- Creating an App Service Plan
- Creating a Web App
- Verifying resource reuse
- Verifying naming convention compliance
- Verifying tag assignment
- Executing repeated deployments
- Confirming idempotent behavior

---

## AZ-104 Topics

- Azure App Service
- App Service Plans
- Web Apps
- PaaS
- Scaling
- Deployment Slots
- Managed Identity
- Azure Monitor
- Application Settings
- Custom Domains
- TLS/SSL

---

## Common Interview Topics

- What is Azure App Service?
- What is an App Service Plan?
- App Service Plan vs Web App
- Windows vs Linux App Service
- Scaling options
- Deployment Slots
- Managed Identity integration
- App Service pricing tiers
- App Service vs Virtual Machine

---

## Common Mistakes

- Confusing App Service Plan with Web App
- Selecting the wrong pricing tier
- Deploying directly to production without slots
- Missing monitoring configuration
- Not using Managed Identity where possible
- Ignoring scaling requirements
- Assuming App Service provides full VM-level control

---

## Simple Analogy

An App Service Plan is like a building.

A Web App is like a business renting space inside that building.

The building provides the compute resources, while the application uses those resources to serve users.

Multiple applications can share the same building if the capacity is sufficient.

---

## Key Takeaways

- App Service is Azure's managed platform for hosting web applications.
- App Service Plans provide the underlying compute capacity.
- Web Apps host the application workload.
- The module supports safe, repeatable, idempotent deployments.
- App Service is a core Azure PaaS service and an important AZ-104 topic.
