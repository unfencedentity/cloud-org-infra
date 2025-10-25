# Operations Guide

## Overview
This document describes the operational procedures for maintaining the `cloud-org-infra` environment.

## Deployment Workflow
1. Authenticate to Azure:
Connect-AzAccount

2. Run full environment deployment:
./automation/deploy-environment.ps1 -Env dev -Region weu -AppName core

3. Verify compliance using Azure Policy dashboard.
4. Use cleanup script to remove non-production resources:
./automation/cleanup.ps1 -Env dev -Region weu -AppName core -Force


## Maintenance
- **Tag Review:** Ensure all resources have required tags (`env`, `owner`, `costCenter`, `app`, `dataClass`).
- **Naming Compliance:** All resources follow `{env}-{svc}-{region}-{name}`.
- **Policy Updates:** Review policy JSONs quarterly.
- **Automation Scripts:** Test new scripts in `dev` before merging to `main`.

## Incident Handling
If a resource deployment fails:
- Check GitHub Actions logs (`.github/workflows/deploy.yml`).
- Validate authentication (`Connect-AzAccount` or `AZURE_CREDENTIALS`).
- Use `Get-AzResourceGroupDeployment` to inspect details.
