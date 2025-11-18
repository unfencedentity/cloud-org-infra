# Contributing Guidelines

Thank you for your interest in contributing to **cloud-org-infra**.  
This project follows a structured and modular approach for building Azure infrastructure using PowerShell, Terraform (future), and GitHub Actions.

Please follow the standards below when contributing new modules, scripts, or documentation.

---

## 1. Folder & File Structure

Keep contributions aligned with the repo structure:

automation/  
  modules/         # Reusable PowerShell modules (idempotent)  
  functions/       # Helper functions  
  *.ps1            # Deployment scripts  

architecture/      # Diagrams and infra maps  
documentation/     # Guides, notes, internal docs  
policy/            # Azure Policy definitions  
security/          # RBAC configuration  

---

## 2. Naming Standards

### Resource Groups
- `rg-<area>-<region>`  
- Example: `rg-core-weu`

### Storage Accounts
- `st<area><env><region><unique>`  
- Example: `stcoredevweu2401`

### Scripts
- `create-<component>.ps1`  
- `deploy-<env>.ps1`

---

## 3. Tags Standard

Every resource must include the following tags:

owner = lucian  
env   = dev  
app   = core  

---

## 4. PowerShell Standards

- All scripts **must be idempotent**  
- Use `Ensure-*` naming for functions  
- Avoid hard-coded values  
- Always support parameters  

Example PowerShell parameter block:

    [CmdletBinding()]
    param(
        [string]$ResourceGroup,
        [string]$Location
    )

---

## 5. Git Standards

### Commit messages format:
- `feat: add new module`  
- `fix: correct script error`  
- `docs: update documentation`  
- `refactor: improve script structure`

### Branch naming:
- `feature/<name>`  
- `fix/<name>`  
- `docs/<name>`

---

## 6. Testing Before Commit

Before pushing changes:

- Run PowerShell scripts locally using `pwsh`
- Validate modules with:

      Import-Module .\automation\modules\CoreInfrastructure\CoreInfrastructure.psm1 -Force

- Ensure CI/CD workflow runs successfully in GitHub Actions

---

## 7. Pull Requests

Every change should:
- Clearly explain what was updated  
- Include reasoning and context  
- Update documentation if behavior changed  

---

## 8. Future Conventions

This document will expand as the infrastructure grows:  
- Key Vault  
- VNet topology  
- Private endpoints  
- Terraform modules  
- AKS  
- Monitoring  
- Governance  

---

### 🚀 Thank you for contributing and helping the project grow!
