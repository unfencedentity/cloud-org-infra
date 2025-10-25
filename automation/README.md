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
