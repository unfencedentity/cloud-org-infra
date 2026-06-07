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
