# Create Snapshots

## Purpose

This document describes the snapshot deployment capability for cloud-org-infra.

The snapshot component creates an Azure Managed Disk snapshot from the operating system disk of the core virtual machine.

## Architecture

The workflow performs the following actions:

1. Authenticates to Azure using GitHub Actions OIDC.
2. Runs automation/create-snapshots.ps1.
3. Imports the Snapshots PowerShell module.
4. Retrieves the target virtual machine.
5. Reads the VM operating system managed disk.
6. Creates a snapshot from the OS disk if it does not already exist.
7. Skips creation if the snapshot already exists.

## Files

```text
automation/modules/Snapshots/Snapshots.psm1
automation/create-snapshots.ps1
.github/workflows/deploy-snapshots.yml
documentation/create-snapshots.md
```

## Naming

```text
Resource Group: rg-core-dev-weu
VM: vm-dev-core-weu-01
Snapshot: snap-dev-core-weu-osdisk-01
```

## Idempotency

The deployment is idempotent.

First run:

```text
Snapshot not found. Creating snapshot from source disk...
Snapshot created successfully.
```

Second run:

```text
Snapshot already exists. Skipping creation.
```

## Business Value

This component adds a basic disaster recovery foundation to the platform.

It demonstrates that the environment can not only deploy infrastructure, but also protect existing workloads through recoverable disk snapshots.

## Validation

The workflow was successfully tested from GitHub Actions on the main branch.

Validated behavior:

```text
GitHub Actions workflow succeeded
OIDC authentication succeeded
Snapshots module imported successfully
VM lookup succeeded
OS disk lookup succeeded
Snapshot creation succeeded
Idempotency check succeeded
```

## Current Limitation

This version creates one fixed snapshot:

```text
snap-dev-core-weu-osdisk-01
```

It does not yet create multiple timestamped recovery points.

Restore automation is not included in this version.

## Future Improvements

Planned improvements:

```text
timestamped snapshots
snapshot inventory
snapshot retention policy
restore from snapshot
recovery validation
Recovery Services Vault integration
backup reporting
```

## Operational Notes

Run the workflow manually from GitHub Actions:

```text
Actions
Deploy Snapshots
Run workflow
Branch: main
```

Expected successful result:

```text
Snapshot deployment completed successfully.
```
