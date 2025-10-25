# Resource Inventory

## dev/test/prod
- vnet-{env}-weu
  - snet-web, snet-app, snet-data
- kv-{env}-weu
- la-{env}-weu (Log Analytics), ai-{env}-weu (App Insights)
- st{env}weu (Storage: hot/cool, file)
- sql-{env}-weu (Basic/S0/S2)
- app-{env}-weu (App Service Plan + apps)
- func-{env}-weu (Azure Functions)
- vm-{env}-util-01 (runner/utility)

## Sizing (initial)
- Blob: 20/50/200 GB (dev/test/prod)
- Archive: 500 GB
- DB: 5–20 GB
