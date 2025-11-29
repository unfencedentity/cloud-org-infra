# RBAC Provisioning Module (`create-rbac.ps1`)

## Overview

The **RBAC provisioning module** standardizes role assignments for a given application, environment, and region.  
It assigns Azure Role-Based Access Control (RBAC) roles at the Resource Group scope to a set of Azure AD object IDs (users, groups, or service principals).

The module is located at:

`/automation/create-rbac.ps1`

It is designed to be executed by the main orchestration script (`deploy-environment.ps1`) after the environment has been provisioned.

---

## Responsibilities

For each combination of `App`, `Environment`, and `Region`, the module:

1. Resolves the **Resource Group** (`rg-<app>-<environment>-<region>`).
2. Derives the **scope** from the Resource Group ID.
3. Looks up the built-in role definitions for:
   - `Reader`
   - `Contributor`
   - `Key Vault Secrets User` (if available in the tenant)
4. For each configured identity list:
   - Checks if the role assignment already exists.
   - Creates the assignment only if it is missing (idempotency).

This provides a repeatable, declarative way to enforce access control on cloud-org-infra environments.

---

## Naming and Scope

The module operates at **Resource Group scope**:

- Resource Group name: `rg-<app>-<environment>-<region>`
- Scope: the Resource Group Resource ID

Example:

- `rg-core-dev-weu`
- Scope: `/subscriptions/<sub-id>/resourceGroups/rg-core-dev-weu`

Future versions can extend the logic to resource-level scopes (Key Vault, Storage, etc).

---

## Parameters

### Required

- **Environment** (`string`)  
  Logical environment name (e.g. `dev`, `test`, `prod`).

- **App** (`string`)  
  Application identifier (e.g. `core`, `billing`, `portal`).

- **Region** (`string`)  
  Short region code (e.g. `weu`).

- **Location** (`string`)  
  Azure location string (e.g. `westeurope`).  
  Not used directly in RBAC logic but kept for consistency across modules.

### Optional

All identity-related parameters expect **Azure AD object IDs** (users, groups, or service principals):

- **ReaderObjectIds** (`string[]`)  
  Identities that should receive the **Reader** role at the Resource Group scope.

- **ContributorObjectIds** (`string[]`)  
  Identities that should receive the **Contributor** role at the Resource Group scope.

- **KeyVaultSecretsUserObjectIds** (`string[]`)  
  Identities that should receive the **Key Vault Secrets User** role at the Resource Group scope  
  (role must exist in the tenant; otherwise a warning is emitted).

---

## Behavior and Idempotency

For each combination of `ObjectId`, `RoleName`, and `Scope`, the module:

1. Calls `Get-AzRoleAssignment` with:
   - `-ObjectId`
   - `-RoleDefinitionName`
   - `-Scope`
2. If an assignment already exists:
   - Logs that it is reusing the existing assignment.
   - Does not create a duplicate.
3. If no assignment exists:
   - Calls `New-AzRoleAssignment` using the role definition ID and the scope.

All write operations are wrapped in `ShouldProcess`, which enables:

- `-WhatIf` simulation
- `-Confirm` for interactive confirmations

This makes the module safe to run repeatedly and in automated pipelines.

---

## Dependencies

This module assumes:

- The **Resource Group** has already been created (`create-rg.ps1`).
- The current Azure context (subscription/tenant) has been set upfront  
  (usually by the orchestrator via a Service Principal or user login).

---

## Execution Flow Summary

1. Validate that the Resource Group exists.
2. Resolve the Resource Group ID and scope.
3. Load the role definitions:
   - Reader
   - Contributor
   - Key Vault Secrets User (if available)
4. For each identity list:
   - Check for existing role assignments.
   - Create missing assignments only.
5. Return the set of role assignments for the Resource Group scope.

This module provides a reusable and auditable pattern for applying RBAC to application environments.
