# Support & Issue Management

This document describes the **support model**, **issue reporting workflow**, and **expected responsibilities** for users of the `cloud-org-infra` automation framework.

Although this repository is open for extension and internal use, it follows a strict, enterprise-grade operational support structure to ensure reliability, stability, and predictable behavior across environments.

---

# 1. Support Scope

The following areas are **officially supported**:

### ✔ Provisioning Modules
All modules under `automation/` including:
- Resource Groups
- Network & Subnets
- Network Security Groups
- Storage Accounts
- Key Vault
- App Service & App Service Extended
- Log Analytics Workspace
- Application Insights
- Alerts module
- RBAC module

### ✔ Orchestration
- Full end-to-end deployment using `deploy-environment.ps1`
- Authentication flow (local + CI/CD)

### ✔ Documentation
- Module docs
- Architecture overview
- Runbooks
- Operational fundamentals

### ✔ Security & Governance Baselines
- RBAC assignments
- Tagging enforcement
- Identity and access principles
- Azure Policy templates (if applicable)

---

# 2. Out-of-Scope (Not Supported)

The framework **does not support** the following:

✘ Manual edits made directly in Azure Portal  
✘ Custom user roles outside defined RBAC baseline  
✘ Deployment of non-standard Azure services not included in automation  
✘ Breaking changes introduced by users without documentation updates  
✘ Feature requests without proper justification or architecture impact analysis  
✘ Ad-hoc scripts placed outside the automation structure  

---

# 3. Issue Types

All issues fall under one of the categories below:

### **Type A — Provisioning Failure**
Examples:
- Module throws an exception
- Missing parameters
- Naming violations
- Failed idempotency check

### **Type B — Configuration Drift**
Examples:
- Azure resource differs from the expected state
- Manual changes cause orchestration failures
- Missing tags or wrong properties on resources

### **Type C — Documentation Issues**
Examples:
- Incorrect examples
- Missing sections
- Outdated module descriptions

### **Type D — Feature Requests**
Examples:
- New module
- New alert rule
- Additional App Service configuration
- New governance policy

### **Type E — Security Concerns**
Examples:
- Excessive RBAC permissions
- Identity misconfiguration
- Missing encryption settings
- Public exposure of resources

---

# 4. Severity Levels (SLA Model)

Each issue should be assigned a severity for prioritization:

### 🔥 SEV-1 — Critical
- Deployment completely blocked
- Production environment impacted
- Security exposure or misconfiguration

**Target Response:** < 2 hours  
**Target Fix:** Immediate hotfix

### ⚠️ SEV-2 — High
- Non-production environment blocked
- Module failing in repeatable scenarios
- Incorrect RBAC or policy enforcement

**Target Response:** Same day  
**Target Fix:** 1–2 days

### ⚙️ SEV-3 — Medium
- Minor provisioning issues
- Documentation gaps
- Non-critical inconsistencies

**Target Response:** 1–2 days  
**Target Fix:** 3–5 days

### ℹ️ SEV-4 — Low
- Cosmetic fixes
- Refactors
- Non-urgent enhancements

**Target Response:** 3–5 days  
**Fix:** As scheduled

---

# 5. How to Request Support

To request support, open an issue including the following template:

### Required Information:
1. **Issue Type:** (A/B/C/D/E)
2. **Severity:** (SEV-1/2/3/4)
3. **Environment:** dev/test/prod
4. **Module(s) Affected:** create-xxx.ps1
5. **Exact Command Used:** include full parameters
6. **Console Output:** paste the full relevant logs
7. **Expected Behavior:** what should have happened
8. **Actual Behavior:** what happened instead

Issues without complete information may be rejected.

---

# 6. Feature Request Workflow

All feature requests must include:

1. Business justification  
2. Architectural impact  
3. Dependencies (KeyVault, LAW, AppInsights, RBAC)  
4. Proposed naming conventions  
5. Required changes to documentation  
6. Required changes to orchestrator  

Requests may be accepted or declined based on framework direction.

---

# 7. Security Reporting Process

If you identify a security risk:

1. Do **NOT** open a public issue  
2. Report privately following the secure channel  
3. Provide:
   - scenario
   - affected modules
   - potential impact
   - recommended fix

Security fixes receive **highest priority**.

---

# 8. Support Expectations for Users

Users must:

• Not modify Azure resources manually unless documented  
• Maintain consistent naming and tags  
• Run deployments from orchestrator only  
• Follow versioning strategy (VERSIONING.md)  
• Update documentation when introducing changes  
• Never store secrets in the repository or in scripts  

---

# 9. Automated Support Tools

The project includes the following automated helpers:

• Idempotency checks  
• Validation of Azure context  
• Naming conventions baked into scripts  
• RBAC enforcement  
• Diagnostic logs  
• Alerts module for runtime monitoring  

Future implementations may include health checks or drift detection.

---

# 10. End of Support Lifecycle

A module or feature may be deprecated when:

• Azure announces retirement  
• A newer architectural pattern replaces it  
• Terraform takes over the same component through infra2  
• Security or compliance concerns arise  

Deprecated features will be marked in `CHANGELOG.md`.

---

# 11. Summary

The support model ensures:

• predictable deployments  
• strong security posture  
• clear governance  
• fast troubleshooting  
• consistent contributor experience  
• enterprise-grade operational readiness  

If you follow the standards described here, support will be fast, efficient, and professional.

