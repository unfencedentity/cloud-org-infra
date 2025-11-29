```md
                            +-----------------------------+
                            |      deploy-environment.ps1 |
                            |     (Central Orchestrator)  |
                            +--------------+--------------+
                                           |
                                           v

                    +---------------------------------------------+
                    |         Sequential Provisioning Flow        |
                    +---------------------------------------------+
                                           |
                    -----------------------------------------------------
                    |                     |                   |         |
                    v                     v                   v         v

   +------------------------+   +-----------------------+   +-----------------------+
   |     create-rg.ps1      |   |  create-network.ps1  |   |    create-nsgs.ps1    |
   |   Resource Group       |   |  VNet + Subnets      |   |   NSGs per Subnet     |
   +-----------+------------+   +-----------+-----------+   +-----------+-----------+
               |                            |                           |
               |                            v                           |
               |                +------------------------+               |
               |                |   create-storage.ps1   |               |
               |                |   Storage Account      |               |
               |                +-----------+------------+               |
               |                            |                           |
               v                            v                           v

   +------------------------+   +----------------------------+   +---------------------------+
   |  create-keyvault.ps1   |   |   create-loganalytics.ps1 |   |   create-appinsights.ps1  |
   |   Key Vault per env    |   | Log Analytics Workspace   |   | Application Insights (AI) |
   |  Secrets isolation     |   | Observability Core        |   | Telemetry + Metrics       |
   +-----------+------------+   +-------------+-------------+   +-------------+-------------+
               |                            |                           |
               |                            v                           |
               v                +----------------------------+            v

   +------------------------+   |   create-appservice.ps1    |   +------------------------------+
   |    create-rbac.ps1     |   |   Base Web App + ASP       |   |   create-appservice-extended |
   | RBAC Assignments       |   +-------------+--------------+   |  TLS, MI, HTTPS, LAW Logs    |
   | Least Privilege Model  |                 |                  +-------------+----------------+
   +-----------+------------+                 v                                |
               |                    +--------------------------+               |
               |                    |    create-alerts.ps1     |               |
               |                    | CPU, 5xx, AG alerts      |               |
               |                    +-------------+------------+               |
               |                                  |                            |
               +----------------------------------+----------------------------+
                                                  |
                                                  v

                                +--------------------------------+
                                |   Full Environment Provisioned |
                                |  Secure • Observable • Modular |
                                +--------------------------------+
```
