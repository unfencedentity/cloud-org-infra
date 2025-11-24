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



# Automation Scripts

This folder contains all PowerShell automation used to deploy the cloud-org-infra environment.

## Main entrypoint

To deploy the environment from the automation engine, run:

    cd .\automation\
    .\deploy-environment.ps1 -Environment dev -App core -Region weu -Location westeurope

The deploy-environment.ps1 script:
- Ensures an active Azure context exists (GitHub Actions or local SP)
- Selects the correct subscription
- Calls sub-scripts such as:
  - create-rg.ps1
  - create-network.ps1 (future)
  - create-nsgs.ps1 (future)
  - create-appservice.ps1
  - create-storage.ps1
- Passes common parameters like Environment, App, Region, Location

## Running scripts locally (PowerShell execution policy)

On a clean Windows setup, running any .ps1 file may show an error like:

    ... is not digitally signed. You cannot run this script on the current system.
    PSSecurityException UnauthorizedAccess

This is a local PowerShell security policy, not an Azure or GitHub problem.

To allow running unsigned scripts ONLY in the current window, run:

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

Then run the deployment normally:

    .\deploy-environment.ps1 -Environment dev -App core -Region weu -Location westeurope

Scope Process means the change is temporary and disappears when you close PowerShell.  
This keeps your system safe while allowing local development and testing.

## Notes

- GitHub Actions does not require Set-ExecutionPolicy  
- OIDC-based login works automatically in pipelines  
- Local execution requires either Connect-AzAccount or SP environment variables  
- All scripts are written to be idempotent, meaning they can be safely re-run
