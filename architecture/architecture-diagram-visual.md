```md
┌──────────────────────────────────────────────────────────┐
│                 INFRA — ENTERPRISE STACK                 │
└──────────────────────────────────────────────────────────┘

                       deploy-environment.ps1
                   Orchestration & Automation
                               ↓

────────────────────── Infrastructure Layer ──────────────────────
┌────────────────────┐   ┌─────────────────────┐   ┌──────────────────────┐
│ Resource Group     │   │ Virtual Network     │   │ Network Security     │
│ create-rg.ps1      │   │ create-network.ps1  │   │ create-nsgs.ps1      │
└────────────────────┘   └─────────────────────┘   └──────────────────────┘


────────────────────── Storage & Secrets Layer ─────────────────────
┌──────────────────────┐   ┌─────────────────────────────┐
│ Storage Account      │   │ Key Vault                   │
│ create-storage.ps1   │   │ create-keyvault.ps1         │
│ blob/file/queue      │   │ Secrets & identity          │
└──────────────────────┘   └─────────────────────────────┘


────────────────────── Observability Layer ────────────────────────
┌───────────────────────────────┐   ┌──────────────────────────────┐
│ Log Analytics Workspace       │   │ Application Insights          │
│ create-loganalytics.ps1       │   │ create-appinsights.ps1        │
│ Logs + Metrics + Queries      │   │ App telemetry, perf, traces   │
└───────────────────────────────┘   └──────────────────────────────┘


────────────────────── Application Layer ───────────────────────────
┌────────────────────────────┐   ┌───────────────────────────────────┐
│ Base Web App + ASP         │   │ App Service Extended              │
│ create-appservice.ps1      │   │ create-appservice-extended.ps1    │
│ WebApp hosting             │   │ TLS 1.2 / HTTPS / MI / LAW logs   │
└────────────────────────────┘   └───────────────────────────────────┘


────────────────────── Governance & Security ───────────────────────
┌────────────────────────────┐   ┌───────────────────────────────────┐
│ RBAC                       │   │ Alerts & Action Groups            │
│ create-rbac.ps1            │   │ create-alerts.ps1                 │
│ Least-privilege model      │   │ CPU / 5xx / Availability alerts   │
└────────────────────────────┘   └───────────────────────────────────┘


                           ┌──────────────────────────────┐
                           │   FULL ENVIRONMENT READY      │
                           │ Secure • Observable • Modular │
                           └──────────────────────────────┘
```
