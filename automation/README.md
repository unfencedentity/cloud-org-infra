# Automation Scripts

## Create Resource Group
./create-rg.ps1 -Env dev -Region weu -Name core -Location westeurope


## Create Storage Account
./create-storage.ps1 -Env dev -Region weu -AppName core -Location westeurope

> Numele RG implicit: `{env}-rg-{region}-{app}`.  
> Storage account-ul este generat fără cratime și trunchiat la 24 de caractere, cu 3 caractere random pentru unicitate.

**Prerechizite:** Modulul `Az` instalat și `Connect-AzAccount`/`Az login` activ.


## Cleanup
./cleanup.ps1 -Env dev -Region weu -AppName core -Location westeurope -Force

> Atenție: șterge întregul Resource Group pentru aplicația respectivă.


## Create Network (vNet + Subnets + NSG)
./create-network.ps1 -Env dev -Region weu -AppName core -Location westeurope -AddressPrefix 10.10.0.0/16

> Creează vNet `{env}-vnet-{region}-{app}` și subnets: `snet-web`, `snet-app`, `snet-data` cu NSG-uri dedicate.

## Full Environment Deploy
Run the end-to-end deployment (RG → Network → Storage → App Service):
./deploy-environment.ps1 -Env dev -Region weu -AppName core -Location westeurope


**Prerequisites**
- PowerShell 7+
- Az PowerShell modules installed
- Logged in to Azure (`Connect-AzAccount`) with rights to create resources


