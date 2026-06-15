# OIDC Authentication

## Overview

This document describes how cloud-org-infra authenticates GitHub Actions to Microsoft Azure using OpenID Connect (OIDC) and Federated Credentials.

The implementation eliminates the need for long-lived client secrets and provides a more secure authentication model for CI/CD workflows.

---

## Components

* GitHub Actions
* OpenID Connect (OIDC)
* Microsoft Entra ID
* Service Principal
* Federated Credential
* Azure Subscription

---

## Architecture

GitHub Actions
↓
OIDC Token
↓
Federated Credential
↓
Service Principal
↓
Azure Subscription

---

## Purpose

OIDC authentication provides:

* Secretless authentication
* Reduced credential exposure
* Improved security posture
* Automated trust between GitHub and Azure
* Enterprise-grade CI/CD authentication

---

## Traditional Authentication

Legacy approach:

GitHub Actions
↓
Client Secret
↓
Azure

Challenges:

* Secret rotation
* Secret expiration
* Secret leakage risk
* Credential management overhead

---

## OIDC Authentication Flow

1. GitHub Actions requests an OIDC token.
2. GitHub generates a signed identity token.
3. Microsoft Entra ID validates the token.
4. Federated Credential verifies trust.
5. Service Principal receives access to Azure resources.
6. Deployment proceeds without stored secrets.

---

## Validation

The implementation was validated by:

* Creating a Service Principal
* Configuring Federated Credentials
* Configuring GitHub OIDC trust
* Executing GitHub Actions workflows
* Successfully deploying Azure resources
* Verifying Azure login through OIDC

---

## AZ-104 Topics

* Microsoft Entra ID
* Service Principals
* Managed Identities
* Azure RBAC
* Authentication
* Authorization
* Federated Credentials
* CI/CD Security

---

## Common Interview Topics

* What is OIDC?
* Why use OIDC instead of Client Secrets?
* What is a Federated Credential?
* How does GitHub authenticate to Azure?
* Service Principal vs Managed Identity
* Authentication vs Authorization

---

## Common Mistakes

* Incorrect Federated Credential configuration
* RBAC permissions not assigned
* Repository trust mismatch
* Branch trust mismatch
* Confusing OIDC with Managed Identity

---

## Simple Analogy

OIDC works like a temporary visitor badge. GitHub proves its identity, Azure validates the badge, and temporary access is granted without sharing a permanent password.

---

## Key Takeaways

* OIDC enables secure authentication without storing secrets.
* Federated Credentials establish trust between GitHub and Azure.
* Service Principals perform deployment operations.
* Azure RBAC controls authorized actions after authentication succeeds.
