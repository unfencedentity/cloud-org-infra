# Versioning Strategy

This project follows a **semantic-inspired**, infrastructure-oriented versioning model  
designed for automation toolkits and enterprise cloud environments.

Unlike application codebases, infrastructure automation evolves in **capabilities**,  
not just patches — therefore this repository uses a streamlined interpretation of  
Semantic Versioning that aligns with IaC and operational tooling.

---

## Version Format


Where:

### **MAJOR**
Introduces **significant architectural changes**, breaking modifications, or new  
infrastructure patterns that require operators or environments to adapt.

Examples:
- new networking architecture  
- switching identity model (e.g., migrate to Federated Credentials / OIDC)  
- large-scale reorganization of module structure  
- migration to Terraform-only or hybrid orchestration  

---

### **MINOR**
Adds **new capabilities** that do not break existing deployments.

Examples:
- new provisioning modules (App Insights, Alerts, RBAC, AppService Extended)  
- enhancements to observability or security  
- new automation flows added to `deploy-environment.ps1`  
- documentation improvements that clarify usage  

MINOR increments represent steady evolution of the automation toolkit.

---

### **PATCH**
Small, safe changes that do not alter behavior or features.

Examples:
- small code refactors  
- naming consistency fixes  
- non-functional cleanup  
- documentation tweaks  
- bug fixes that do not change the public interface  

---

## Release Cadence

Releases are created **manually** when a significant collection of changes becomes stable.  
This ensures that version numbers reflect *actual operational milestones*, not arbitrary commits.

Each release should include:
- a version tag (e.g., `v1.2.0`)  
- an entry in `CHANGELOG.md`  
- updated documentation **if applicable**  

---

## Branching Model

The repository uses a simplified branching strategy:

- **`main`** – stable, production-ready automation  
- **feature branches** – for modules, documentation and enhancements  
- **no long-lived development branches** to keep history clean and linear  

All changes should be merged via pull request, even for solo development,  
to maintain clean commit provenance and readable project history.

---

## Backwards Compatibility Policy

- MINOR and PATCH releases **must remain backwards compatible**  
  with existing deployments and module interfaces.
- MAJOR releases **may introduce breaking changes**, but must include:
  - migration notes
  - updated documentation
  - clear architectural overview of the new approach

---

## Summary

Infrastructure automation evolves differently from software engineering.  
This versioning model balances:
- clarity  
- stability  
- predictability  
- portfolio-level professionalism  

By following this scheme, organizations and clients can confidently adopt the  
automation toolkit knowing its roadmap and evolution model are transparent and consistent.
