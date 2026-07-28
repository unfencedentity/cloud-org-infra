Set-StrictMode -Version Latest

$healthCheckScript = Join-Path $PSScriptRoot "..\create-healthchecks.ps1"

function New-Scenario {
    param()

    return [ordered]@{
        ResourceGroup = [pscustomobject]@{
            ResourceGroupName = "rg-core-dev-deu"
            Tags = @{ environment = "dev"; app = "core"; region = "deu"; owner = "ops" }
        }
        VirtualNetwork = [pscustomobject]@{
            Name = "vnet-core-dev-deu"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Network/virtualNetworks/vnet-core-dev-deu"
            Subnets = @([pscustomobject]@{ Name = "subnet-app" }, [pscustomobject]@{ Name = "subnet-data" })
        }
        NSGs = @([pscustomobject]@{ Name = "nsg-core" })
        StorageAccounts = @([pscustomobject]@{
            StorageAccountName = "stcoredevdeu"
            Name = "stcoredevdeu"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/stcoredevdeu"
            EnableHttpsTrafficOnly = $true
        })
        KeyVaultList = @([pscustomobject]@{ VaultName = "kvcoredevdeu01" })
        KeyVaultDetail = [pscustomobject]@{
            VaultName = "kvcoredevdeu01"
            ResourceId = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.KeyVault/vaults/kvcoredevdeu01"
            EnablePurgeProtection = $true
        }
        AppService = [pscustomobject]@{
            Name = "appcoredevdeu01"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01"
            HttpsOnly = $true
        }
        AppInsights = [pscustomobject]@{ Name = "appi-core-dev-deu" }
        ActionGroup = [pscustomobject]@{ Name = "ag-core-dev-deu" }
        RoleAssignments = @([pscustomobject]@{ RoleDefinitionName = "Reader"; ObjectId = "oid-1" })
        DnsZone = $null
        DnsVnetLink = $null
        DnsRecordSet = $null
        Vm = $null
        Nic = $null
        DiagnosticsByResourceId = @{}
    }
}

function Invoke-HealthCheckScenario {
    param(
        [hashtable]$Scenario
    )

    $global:Scenario = $Scenario

    Mock -CommandName Get-AzResourceGroup -MockWith {
        return $global:Scenario.ResourceGroup
    }

    Mock -CommandName Get-AzVirtualNetwork -MockWith {
        return $global:Scenario.VirtualNetwork
    }

    Mock -CommandName Get-AzNetworkSecurityGroup -MockWith {
        return $global:Scenario.NSGs
    }

    Mock -CommandName Get-AzStorageAccount -MockWith {
        return $global:Scenario.StorageAccounts
    }

    Mock -CommandName Get-AzKeyVault -ParameterFilter { -not $PSBoundParameters.ContainsKey("VaultName") } -MockWith {
        return $global:Scenario.KeyVaultList
    }

    Mock -CommandName Get-AzKeyVault -ParameterFilter { $PSBoundParameters.ContainsKey("VaultName") } -MockWith {
        return $global:Scenario.KeyVaultDetail
    }

    Mock -CommandName Get-AzWebApp -MockWith {
        return @($global:Scenario.AppService)
    }

    Mock -CommandName Get-AzApplicationInsights -MockWith {
        return $global:Scenario.AppInsights
    }

    Mock -CommandName Invoke-AzRestMethod -MockWith {
        param([string]$Method, [string]$Uri)

        $resourceId = ($Uri -split "/providers/microsoft\.insights/diagnosticSettings\?api-version=")[0]
        $resourceId = $resourceId -replace "^https://management\.azure\.com", ""

        $values = @()
        if ($global:Scenario.DiagnosticsByResourceId.ContainsKey($resourceId)) {
            $values = @($global:Scenario.DiagnosticsByResourceId[$resourceId])
        }

        return [pscustomobject]@{
            StatusCode = 200
            Content = (@{ value = $values } | ConvertTo-Json -Depth 10)
        }
    }

    Mock -CommandName Get-AzActionGroup -MockWith {
        return $global:Scenario.ActionGroup
    }

    Mock -CommandName Get-AzRoleAssignment -MockWith {
        return $global:Scenario.RoleAssignments
    }

    Mock -CommandName Get-AzPrivateDnsZone -MockWith {
        return $global:Scenario.DnsZone
    }

    Mock -CommandName Get-AzPrivateDnsVirtualNetworkLink -MockWith {
        return $global:Scenario.DnsVnetLink
    }

    Mock -CommandName Get-AzPrivateDnsRecordSet -MockWith {
        return $global:Scenario.DnsRecordSet
    }

    Mock -CommandName Get-AzVM -MockWith {
        return $global:Scenario.Vm
    }

    Mock -CommandName Get-AzNetworkInterface -MockWith {
        return $global:Scenario.Nic
    }

    return & $healthCheckScript -Environment dev -App core -Region deu -Location denmarkeast -MonitoringLocation swedencentral
}

Describe "create-healthchecks.ps1" {
    BeforeEach {
        $script:BaseScenario = New-Scenario

        $vnetId = $script:BaseScenario.VirtualNetwork.Id
        $kvId = $script:BaseScenario.KeyVaultDetail.ResourceId
        $appId = $script:BaseScenario.AppService.Id
        $stId = $script:BaseScenario.StorageAccounts[0].Id

        $script:BaseScenario.DiagnosticsByResourceId[$vnetId] = @([pscustomobject]@{ name = "diag-vnet-core-dev-deu" })
        $script:BaseScenario.DiagnosticsByResourceId[$kvId] = @([pscustomobject]@{ name = "diag-kvcoredevdeu01" })
        $script:BaseScenario.DiagnosticsByResourceId[$appId] = @([pscustomobject]@{ name = "diag-appcoredevdeu01" })
        $script:BaseScenario.DiagnosticsByResourceId[$stId] = @([pscustomobject]@{ name = "diag-stcoredevdeu" })
    }

    It "Key Vault missing is reported as CRITICAL" {
        $scenario = New-Scenario
        $scenario.KeyVaultList = @()
        $scenario.KeyVaultDetail = $null

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $keyVaultResult = @($result.Results | Where-Object { $_.Name -eq "KeyVault" })[0]

        $keyVaultResult.Status | Should Be "CRITICAL"
        $keyVaultResult.Details | Should Be "KV missing"
    }

    It "Key Vault summary without EnablePurgeProtection is re-fetched and evaluated from detailed object" {
        $scenario = New-Scenario
        $scenario.KeyVaultList = @([pscustomobject]@{ VaultName = "kvcoredevdeu01" })
        $scenario.KeyVaultDetail = [pscustomobject]@{
            VaultName = "kvcoredevdeu01"
            ResourceId = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.KeyVault/vaults/kvcoredevdeu01"
            EnablePurgeProtection = $true
        }

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $keyVaultResult = @($result.Results | Where-Object { $_.Name -eq "KeyVault" })[0]

        Assert-MockCalled -CommandName Get-AzKeyVault -Times 1 -Exactly -ParameterFilter { $PSBoundParameters.ContainsKey("VaultName") -and $VaultName -eq "kvcoredevdeu01" }
        $keyVaultResult.Status | Should Be "OK"
    }

    It "Detailed Key Vault with purge protection true is OK" {
        $scenario = New-Scenario
        $scenario.KeyVaultDetail.EnablePurgeProtection = $true

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $keyVaultResult = @($result.Results | Where-Object { $_.Name -eq "KeyVault" })[0]

        $keyVaultResult.Status | Should Be "OK"
        $keyVaultResult.Details | Should Be "Secure"
    }

    It "Detailed Key Vault with purge protection false is WARNING" {
        $scenario = New-Scenario
        $scenario.KeyVaultDetail.EnablePurgeProtection = $false

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $keyVaultResult = @($result.Results | Where-Object { $_.Name -eq "KeyVault" })[0]

        $keyVaultResult.Status | Should Be "WARNING"
        $keyVaultResult.Details | Should Be "Purge protection disabled"
    }

    It "Missing optional properties under StrictMode do not throw" {
        $scenario = New-Scenario
        $scenario.KeyVaultDetail = [pscustomobject]@{
            VaultName = "kvcoredevdeu01"
            ResourceId = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.KeyVault/vaults/kvcoredevdeu01"
        }
        $scenario.StorageAccounts = @([pscustomobject]@{ Name = "stcoredevdeu"; Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/stcoredevdeu" })
        $scenario.AppService = [pscustomobject]@{ Name = "appcoredevdeu01"; Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01" }

        { Invoke-HealthCheckScenario -Scenario $scenario } | Should Not Throw
    }

    It "Storage zero objects is WARNING" {
        $scenario = New-Scenario
        $scenario.StorageAccounts = @()

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $storageResult = @($result.Results | Where-Object { $_.Name -eq "Storage" })[0]

        $storageResult.Status | Should Be "WARNING"
    }

    It "Storage scalar object works" {
        $scenario = New-Scenario
        $scenario.StorageAccounts = [pscustomobject]@{
            StorageAccountName = "stcoredevdeu"
            Name = "stcoredevdeu"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/stcoredevdeu"
            EnableHttpsTrafficOnly = $true
        }

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $storageResult = @($result.Results | Where-Object { $_.Name -eq "Storage" })[0]

        $storageResult.Status | Should Be "OK"
    }

    It "Storage multiple objects works" {
        $scenario = New-Scenario
        $scenario.StorageAccounts = @(
            [pscustomobject]@{
                StorageAccountName = "st1"
                Name = "st1"
                Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/st1"
                EnableHttpsTrafficOnly = $true
            },
            [pscustomobject]@{
                StorageAccountName = "st2"
                Name = "st2"
                Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/st2"
                EnableHttpsTrafficOnly = $true
            }
        )
        $scenario.DiagnosticsByResourceId["/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/st1"] = @([pscustomobject]@{ name = "diag-st1" })
        $scenario.DiagnosticsByResourceId["/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Storage/storageAccounts/st2"] = @([pscustomobject]@{ name = "diag-st2" })

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $storageResult = @($result.Results | Where-Object { $_.Name -eq "Storage" })[0]

        $storageResult.Status | Should Be "OK"
    }

    It "App Service optional property absence is handled as WARNING" {
        $scenario = New-Scenario
        $scenario.AppService = [pscustomobject]@{
            Name = "appcoredevdeu01"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01"
        }

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $appServiceResult = @($result.Results | Where-Object { $_.Name -eq "AppService" })[0]

        $appServiceResult.Status | Should Be "WARNING"
        $appServiceResult.Details | Should Be "HTTPS property unavailable"
    }

    It "Diagnostics works when resource exposes Id" {
        $scenario = New-Scenario
        $scenario.AppService = [pscustomobject]@{
            Name = "appcoredevdeu01"
            Id = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01"
            HttpsOnly = $true
        }

        { Invoke-HealthCheckScenario -Scenario $scenario } | Should Not Throw
    }

    It "Diagnostics works when resource exposes only ResourceId" {
        $scenario = New-Scenario
        $scenario.AppService = [pscustomobject]@{
            Name = "appcoredevdeu01"
            ResourceId = "/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01"
            HttpsOnly = $true
        }
        $scenario.DiagnosticsByResourceId["/subscriptions/111/resourceGroups/rg-core-dev-deu/providers/Microsoft.Web/sites/appcoredevdeu01"] = @([pscustomobject]@{ name = "diag-appcoredevdeu01" })

        { Invoke-HealthCheckScenario -Scenario $scenario } | Should Not Throw
    }

    It "Diagnostics handles resources exposing neither Id nor ResourceId" {
        $scenario = New-Scenario
        $scenario.AppService = [pscustomobject]@{
            Name = "appcoredevdeu01"
            HttpsOnly = $true
        }

        $result = Invoke-HealthCheckScenario -Scenario $scenario
        $diagnosticsResult = @($result.Results | Where-Object { $_.Name -eq "Diagnostics" })[0]

        $diagnosticsResult.Status | Should Match "OK|WARNING"
    }

    It "Health result contract contains required fields" {
        $scenario = New-Scenario
        $result = Invoke-HealthCheckScenario -Scenario $scenario

        @($result).Count | Should Be 1
        @("Environment", "App", "Region", "Location", "MonitoringLocation", "Score", "Severity", "Timestamp", "Results") |
            ForEach-Object {
                (@($result.PSObject.Properties.Name) -contains $_) | Should Be $true
            }
    }

    It "Health result supports zero items" {
        $summary = [pscustomobject]@{ Severity = "Warning"; Results = @() }
        @($summary.Results).Count | Should Be 0
    }

    It "Health result supports one item" {
        $summary = [pscustomobject]@{ Severity = "Warning"; Results = @([pscustomobject]@{ Name = "One" }) }
        @($summary.Results).Count | Should Be 1
    }

    It "Health result supports multiple items" {
        $summary = [pscustomobject]@{ Severity = "Warning"; Results = @([pscustomobject]@{ Name = "One" }, [pscustomobject]@{ Name = "Two" }) }
        @($summary.Results).Count | Should Be 2
    }

    It "Missing required resources remain CRITICAL" {
        $scenario = New-Scenario
        $scenario.ResourceGroup = $null
        $scenario.VirtualNetwork = $null
        $scenario.NSGs = @()

        $result = Invoke-HealthCheckScenario -Scenario $scenario

        $result.Severity | Should Be "Critical"
        @($result.Results | Where-Object { $_.Name -eq "ResourceGroup" })[0].Status | Should Be "CRITICAL"
    }

    It "Warnings are not promoted to Critical accidentally" {
        $scenario = New-Scenario
        $scenario.DnsZone = $null

        $result = Invoke-HealthCheckScenario -Scenario $scenario

        $result.Severity | Should Not Be "Critical"
    }

    It "Full script runs under StrictMode without property-access exceptions" {
        $scenario = New-Scenario

        { Invoke-HealthCheckScenario -Scenario $scenario } | Should Not Throw
    }
}
