# Changelog

All notable changes to **cloud-org-infra** will be documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),  
and this project adheres to a semantic, human-readable versioning scheme.

---

## [1.2.0] - Complete Enterprise Baseline

### Added
- Extended App Service configuration module (`create-appservice-extended.ps1`)
  - HTTPS-only enforcement
  - Minimum TLS version configuration
  - System-assigned managed identity
  - Always On configuration
  - Diagnostic logs streaming to Log Analytics
- Application Insights provisioning module (`create-appinsights.ps1`)
- Alerts module (`create-alerts.ps1`)
  - CPU High metric alert
  - HTTP 5xx spike metric alert
  - Action Group automation
- RBAC module (`create-rbac.ps1`)
  - Reader, Contributor, Key Vault Secrets User roles at Resource Group scope
- Full documentation for:
  - App Service Extended
  - Application Insights
  - Alerts
  - RBAC
- Orchestrator enhancements (`deploy-environment.ps1`):
  - Integration of App Service Extended, Alerts and RBAC
  - Updated orchestration summary messaging

### Improved
- Root README rewritten in enterprise / portfolio style
- Documentation structure under `/documentation` aligned across all modules

---

## [1.1.0] - Observability & Documentation

### Added
- Log Analytics Workspace provisioning module (`create-loganalytics.ps1`)
- Initial Application Insights integration patterns
- Documentation for:
  - Resource Group provisioning
  - Virtual Network and subnets
  - Network Security Groups
  - Storage Account
  - Key Vault
  - App Service
  - Log Analytics Workspace
- Operations guide and core runbook under `/documentation/practice`
- Architecture and fundamentals documentation under:
  - `/documentation/architecture`
  - `/documentation/fundamentals`

### Improved
- Standardized naming conventions across all core resources
- Tagging model (`environment`, `app`, `region`, `owner`) consistently applied

---

## [1.0.0] - Initial Infrastructure Baseline

### Added
- Core automation modules:
  - `create-rg.ps1` — Resource Group provisioning
  - `create-network.ps1` — Virtual Network and subnets
  - `create-nsgs.ps1` — Network Security Groups
  - `create-storage.ps1` — Storage Account
  - `create-keyvault.ps1` — Key Vault
  - `create-appservice.ps1` — App Service Plan and Web App
- Main orchestrator:
  - `deploy-environment.ps1` with parameterized Environment/App/Region/Location
- Cleanup script:
  - `cleanup.ps1` for removing entire environments
- Security and policy scaffolding:
  - `/security` and `/policy` folders with initial matrices and templates

---

## [Unreleased]

Planned items (tracked at roadmap level, subject to change):

- Terraform mirror repository (`cloud-org-infra2`)
- Optional Application Gateway + WAF module
- Optional database modules (SQL / PostgreSQL)
- GitHub Actions templates for continuous delivery of environments
