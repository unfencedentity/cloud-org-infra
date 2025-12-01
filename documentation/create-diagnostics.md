Module Documentation — create-diagnostics.ps1
Centralized Diagnostic Settings for Azure Resources

Overview:
This module configures Diagnostic Settings for all supported Azure resources and routes all logs and metrics to a central Log Analytics Workspace (LAW). It is fully automated, idempotent, naming-driven, and aligned with Landing Zone best practices.

1. Automatic Resource Discovery:
- The script dynamically discovers resources using naming conventions and tags.
- Log Analytics Workspace follows: la-<App>-<Environment>-<Region>
- Key Vault follows: kv-<App>-<Environment>-<Region>
- Storage accounts use tags: app=<App>, environment=<Environment>
This removes all hardcoding and ensures multi-environment and multi-region compatibility.

2. Unified Logs & Metrics (CategoryGroup):
All diagnostic settings use:
- CategoryGroup = AllLogs
- CategoryGroup = AllMetrics
This ensures complete observability, standardized monitoring, SIEM compatibility, and zero maintenance when Azure adds new diagnostic categories.

3. Fully Idempotent:
Before applying a diagnostic setting, the script checks:
Get-AzDiagnosticSetting | Where-Object { $_.Name -eq $SettingName }
If the setting exists, it is SKIPPED.
If not, it is CREATED.
This makes the module safe for:
- CI/CD pipelines
- Daily/weekly operational runs
- Re-deployments
- Multi-region rollouts
- Zero-duplication monitoring

4. Consistent Naming:
Diagnostic settings follow this global pattern:
diag-<resource-name>
Examples:
diag-vnet-core-dev-weu
diag-kv-core-dev-weu
diag-app-core-dev-weu
This ensures predictable governance, easy audits, and simplified observability.

5. Supported Resource Types:
The module currently supports:
- Virtual Networks (VNets)
- Network Security Groups (NSGs)
- Storage Accounts
- Key Vaults
- App Service Plans
- App Services
- Log Analytics (as destination only)
- Application Insights (already provides logs natively)
Future planned additions:
- Virtual Machines
- API Management
- Cosmos DB
- Azure SQL
- EventHub logs
- Long-term storage auditing

6. Operational Flow:
1. Load parameters (App, Environment, Region, Location)
2. Identify the Log Analytics workspace
3. Discover all Azure resources that support diagnostic settings
4. Build a standardized diagnostic setting name (diag-<resource>)
5. Check if diagnostic setting already exists
6. If not, create it using AllLogs + AllMetrics
7. Output final status for each resource
The entire process is 100% automated and environment-agnostic.

7. Why it matters for clients:
This module gives companies:
- Full security visibility
- Centralized monitoring
- Lower operational costs
- Compliance readiness (ISO, SOC2, CIS)
- A scalable, repeatable monitoring foundation
- Automated governance across all environments

8. Why it matters for you (as a consultant):
With this module you deliver:
- Enterprise-grade security
- Zero-manual configuration monitoring
- Repeatable, production-ready infrastructure
- A tangible asset you can sell immediately as part of a Landing Zone package
