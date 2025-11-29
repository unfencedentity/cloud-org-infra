# Contributing Guide

Thank you for your interest in contributing to **cloud-org-infra** — an enterprise-grade Azure automation framework built using PowerShell, modular IaC patterns, security-first defaults, and clean orchestration flows.

This document defines the required standards, coding conventions, architectural principles, and operational expectations for contributing to this project. All contributions must align with the structure, quality, and philosophy of the framework.

---

# 1. Core Principles

Every contribution must respect the following:

• Predictability — provisioning must be deterministic and repeatable  
• Idempotency — scripts must safely re-run without breaking anything  
• Security — no secrets in code, least-privilege RBAC, identity-first design  
• Consistency — naming, tagging, structure, and documentation must follow standards  
• Professionalism — enterprise-grade clarity, modularity, and maintainability  
• Observability — logs and monitoring should be integrated naturally  

---

# 2. Repository Structure

All contributions must fit inside the existing repository layout:

automation/
    create-*.ps1           → provisioning modules
    deploy-environment.ps1 → main orchestrator
    functions/             → shared helper functions
architecture/              → diagrams and high-level descriptions
documentation/             → module docs, runbooks, fundamentals, architecture
policy/                    → governance templates and recommended Azure Policies
security/                  → RBAC models, access matrices, security baselines
tools/                     → optional helper scripts

No new folder should be introduced unless it has architectural justification.

---

# 3. Naming Standards

All resources must follow strict, deterministic naming:

Resource Groups:
  rg-<app>-<env>-<region>

Virtual Network:
  vnet-<app>-<env>-<region>

Subnets:
  snet-<app>-<env>-<region>-<purpose>

Storage Accounts:
  st<app><env><region><unique>

Key Vault:
  kv-<app>-<env>-<region>

App Service Plan:
  asp-<app>-<env>-<region>

Web App:
  app-<app>-<env>-<region>

Log Analytics Workspace:
  law-<app>-<env>-<region>

Application Insights:
  appi-<app>-<env>-<region>

All naming must remain lowercase, dash-separated, globally deterministic, and compliant with Azure naming rules.

---

# 4. Tagging Standards

All resources must include, at minimum, the following tags:

environment = <env>
app         = <app>
region      = <region>
owner       = cloud-org-infra

Tags must be applied consistently across all modules.

---

# 5. PowerShell Standards

All provisioning scripts must follow the same structure:

• CmdletBinding enabled  
• Typed parameters  
• ValidateSet / ValidateNotNullOrEmpty where appropriate  
• Consistent parameter order: Environment, App, Region, Location  
• Deterministic naming based on conventions  
• Idempotency checks using Get-Az* commands  
• ShouldProcess support for safe dry-run  
• Errors must throw and stop execution  
• Logs should be clean, informative, and without debug noise  

Every script must begin with:

$ErrorActionPreference = "Stop"

No script may rely on implicit context — authentication must be done in orchestrator only.

---

# 6. Idempotency Requirements

A module must:

1. Check if the resource already exists  
2. Return the existing resource if found  
3. Only create missing resources  
4. Never overwrite or delete resources unless explicitly designed for it  
5. Remain safe to run 50+ times with identical output  

This is fundamental.

---

# 7. Module Requirements

Each new module must include:

• Parameters: Environment, App, Region, Location  
• Resource naming using conventions  
• Tags  
• Idempotency  
• Logging  
• Final return of the provisioned object  
• Documentation under /documentation  

Modules that configure resources (e.g., *extended*, *rbac*, *alerts*) must be similarly structured.

---

# 8. Documentation Requirements

For each module, create a file under:

documentation/create-<module>.md

Documentation must include:

• Overview  
• Responsibilities  
• Parameters  
• Execution behavior  
• Idempotency characteristics  
• Dependencies  
• Example usage  

High-level docs (architecture, fundamentals, runbooks, operations) must remain up to date.

README.md must reflect all major capabilities after each MINOR or MAJOR release.

---

# 9. Orchestrator Integration

If a module is expected to run during full deployment:

1. Add its script path to deploy-environment.ps1  
2. Add Test-Path validation  
3. Add execution block following the established order  
4. Update the final orchestration summary line  
5. Ensure ShouldProcess behavior remains consistent  

Orchestration order must remain logical:

RG → Network → NSGs → Storage → KeyVault → LAW → AppService → AppInsights → AppServiceExtended → Alerts → RBAC

---

# 10. Commit Standards

Use a clear commit message format:

feat(module): add <feature>  
fix(module): correct <issue>  
docs(module): update documentation  
refactor(module): rewrite logic without changing behavior  
security: improve RBAC, identity, or secret handling  
chore: cleanup, small adjustments  

Commits must be small, focused, and atomic.

---

# 11. Branch Standards

Branches should follow:

feature/<name>  
fix/<name>  
docs/<name>  
refactor/<name>  

Merge only via Pull Request, even for solo development, to preserve reviewability.

---

# 12. Testing Requirements

Before committing:

• Run the module standalone  
• Run full orchestration for a test environment  
• Validate resource creation in Azure Portal  
• Confirm idempotency by re-running deploy-environment.ps1  
• Ensure no warnings, errors, or unintended changes appear  

Testing matrix:

Local: pwsh / Az modules  
Pipeline: GitHub Actions workflow  
Azure: All resources created as expected  

---

# 13. Security Requirements

• No secrets in repository, ever  
• No hardcoded credentials  
• Use Managed Identity wherever possible  
• RBAC must be minimal and explicit  
• Modules must not weaken security posture  
• KeyVault access must remain principle-of-least-privilege  
• No public endpoints unless explicitly required  

Security documentation is maintained in SECURITY.md.

---

# 14. Governance & Policy Requirements

If adding governance elements:

• Place Azure Policy samples in /policy  
• Place RBAC matrices in /security  
• Mention changes in CHANGELOG.md  
• Ensure naming & tagging enforcement remains consistent  

---

# 15. Pull Request Requirements

Each PR must provide:

• Summary of what changed  
• Reason for the change  
• Validation evidence (idempotency test, deployment test)  
• Updated documentation if behavior changed  
• Updated README if capabilities changed  
• Updated CHANGELOG.md for new features  

No PR is accepted without documentation.

---

# 16. Contribution Philosophy

cloud-org-infra is designed as a **professional cloud automation framework**, not a quick script repo.  
Every contribution must increase clarity, maintainability, and enterprise readiness.

Thank you for helping this project grow into a world-class automation toolkit.
