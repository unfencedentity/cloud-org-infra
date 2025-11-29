                       +-----------------------------+
                       |      deploy-environment.ps1 |
                       |   (Central Orchestrator)   |
                       +--------------+--------------+
                                      |
                                      v
        +-------------------------------------------------------------+
        |                 Sequential Provisioning Flow                |
        +-------------------------------------------------------------+
                                      |
               -------------------------------------------------
               |               |               |               |
               v               v               v               v

+--------------------+   +--------------------+   +---------------------+
|   create-rg.ps1    |   | create-network.ps1 |   |  create-nsgs.ps1    |
| Resource Group     |   | VNet + Subnets     |   | Network Security    |
| provisioning       |   | segmentation        |   | Groups per subnet   |
+---------+----------+   +----------+---------+   +-----------+---------+
          |                         |                         |
          |                         v                         |
          |               +--------------------+              |
          |               | create-storage.ps1 |              |
          |               | Storage Account    |              |
          |               +---------+----------+              |
          |                         |                         |
          v                         v                         v

+---------------------+   +---------------------+   +----------------------+
| create-keyvault.ps1 |   | create-loganalytics |   | create-appinsights. |
| Key Vault per env   |   | Log Analytics WS    |   | Application Insights |
| secrets isolation   |   | observability core  |   | telemetry + metrics  |
+----------+----------+   +----------+----------+   +-----------+----------+
           |                         |                          |
           |                         v                          |
           v                 +-------------------+              v

+-----------------------+   | create-appservice  |   +-----------------------+
| create-rbac.ps1       |   |  Base Web App      |   | create-appservice-    |
| RBAC assignments      |   | ASP + WebApp       |   | extended.ps1          |
| least-privilege model |   +---------+----------+   | Hardening + Identity  |
+-----------+-----------+             |              | TLS, MI, Logs to LAW  |
            |                         v              +-----------+-----------+
            |                 +------------------+               |
            |                 | create-alerts.ps1 |               |
            |                 | CPU, 5xx, AG      |               |
            |                 +---------+---------+               |
            |                           |                         |
            +---------------------------+-------------------------+
                                        |
                                        v
                         +--------------------------------+
                         |  Full Environment Provisioned   |
                         |  Secure • Observable • Modular  |
                         +--------------------------------+
