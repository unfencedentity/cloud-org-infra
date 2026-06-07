# Backup and Recovery

## Components

- Recovery Services Vault
- Backup Policy
- VM Backup Protection
- Recovery Points

## Architecture

VM
↓
Backup Policy
↓
Backup Job
↓
Recovery Services Vault
↓
Recovery Point

## Validation

The implementation was validated by:

- Deploying Recovery Services Vault
- Deploying Backup Policy
- Enabling VM Backup Protection
- Running on-demand backup
- Verifying recovery point creation
- Confirming idempotent workflow execution

## AZ-104 Topics

- Recovery Services Vault
- Backup Policies
- Backup Jobs
- Recovery Points
- Restore Operations

- ## Recovery Types

### Snapshot
- Fast point-in-time disk copy
- Short-term operational recovery

### VM Backup
- Policy-based protection
- Recovery Services Vault storage
- Long-term retention
- Full VM restore support
