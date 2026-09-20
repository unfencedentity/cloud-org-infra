# Naming Convention Policy

## Purpose

This policy defines predictable, readable, and repeatable names for Azure resources deployed by Cloud Org Infra.

## Standard Pattern

```text
<resource-type>-<application>-<environment>-<region>[-<instance>]
```

## Components

| Component | Description | Examples |
|---|---|---|
| `resource-type` | Approved Azure resource abbreviation | `rg`, `vnet`, `nsg`, `kv`, `st`, `mi`, `vm`, `asp`, `app`, `law`, `appi`, `pe` |
| `application` | Workload or application identifier | `core`, `billing`, `portal` |
| `environment` | Deployment lifecycle stage | `dev`, `test`, `prod` |
| `region` | Short Azure region code | `deu`, `weu`, `neu`, `eus`, `wus` |
| `instance` | Optional instance number | `01`, `02` |

The default deployment region is `deu`, mapped to Azure region `denmarkeast`.

## Examples

- `rg-core-dev-deu`
- `vnet-core-prod-deu`
- `nsg-portal-test-deu`
- `vm-core-prod-deu-01`

## Globally Unique Resource Names

Azure Storage accounts, Key Vaults, and Web Apps require globally unique names. The deployment naming helper removes hyphens where required and appends a deterministic hash derived from the subscription:

- `stcoredevdeu<hash>`
- `kvcoredevdeu<hash>`
- `appcoredevdeu<hash>`

## Rules

- Use lowercase names.
- Do not use spaces or underscores.
- Use approved resource-type and region abbreviations.
- Use deterministic names for repeatable deployments.
- Add an instance number only when multiple resources of the same type are required.
- Generate deployment names through `automation/shared/DeploymentNaming.ps1`.

## Governance

`policy/policies/enforce-naming-regex.json` provides audit visibility for naming compliance. Audit findings do not block deployment and should be reviewed before production approval.