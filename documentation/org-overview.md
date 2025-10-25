# Org Overview (v0.1)

## Team (8)
- Cloud Lead (1)
- Cloud Engineer (2)
- Developer (2)
- Data/AI Engineer (1)
- SRE/Support (1)
- PM/Tech Writer (1)

## Environments
dev, test, prod

## Resource Catalog (per env)
- Identity: Entra ID groups, RBAC
- Network: vNet + 3 subnets (web/app/data), NSG
- Compute: App Service (B1/P1v3), Functions (consumption), VM utilitar (B2s/D2s_v5)
- Data: Storage Account (blob hot/cool, file share), Azure SQL (Basic/S0/S2)
- AI: Cognitive Services / Azure OpenAI (on demand)
- Security: Key Vault, Defender for Cloud
- Observability: Log Analytics + App Insights
- CI/CD: GitHub Actions (+ self-hosted runner opțional)

## Naming & Tags
- Name: {env}-{svc}-{region}-{name} (ex: prod-app-weu-api)
- Tags: env, owner, costCenter, app, dataClass
