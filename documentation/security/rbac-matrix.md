# RBAC Matrix

| Role            | Dev/Test                  | Prod                                   |
|-----------------|---------------------------|----------------------------------------|
| Cloud Lead      | Owner                     | Contributor + User Access Admin        |
| Cloud Engineer  | Contributor               | Contributor (scoped la RG de aplicație)|
| Developer       | App Service Contributor   | Reader                                 |
| Data/AI Eng     | CogSvc + Storage Contributor | Reader + Key Vault Secrets User     |
| SRE/Support     | Monitoring + Backup Contrib | Monitoring Contrib + Security Reader |
| PM/Writer       | Reader                    | Reader                                 |
