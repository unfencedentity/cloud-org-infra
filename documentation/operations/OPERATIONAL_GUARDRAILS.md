# Operational Guardrails – cloud-org-infra

This document defines non-negotiable safety checks applied before and after infrastructure deployment.

These guardrails apply to all automated deployments managed by cloud-org-infra.

## Purpose
Prevent high-impact misconfigurations by enforcing minimal operational standards before any automation runs.

## Pre-Deployment Guardrails

- Correct Azure subscription is selected
- Required resource providers are registered
- Minimum RBAC permissions are present
- Target region is approved
- Naming collisions are prevented

- Required Azure Resource Providers must be registered (e.g. Microsoft.Storage, Microsoft.Compute, Microsoft.KeyVault, Microsoft.Network). Unregistered providers result in deployment failure and must be remediated before automation runs.

## Post-Deployment Guardrails

- All resources reach `Succeeded` provisioning state
- Diagnostic settings are enabled where required
- No orphaned or partially deployed resources exist

## Why this matters
Guardrails reduce deployment risk, speed up troubleshooting, and enforce operational discipline at scale.