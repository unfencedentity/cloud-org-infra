<#
.SYNOPSIS
Performs prerequisite validation before Azure infrastructure deployment.

.DESCRIPTION
Validates critical deployment conditions before any provisioning logic is executed.

The function checks mandatory inputs, Azure authentication context, subscription alignment,
approved deployment regions, environment naming standards, and local automation path availability.

This acts as a deployment safety gate to reduce failed or unsafe infrastructure runs caused by
missing parameters, wrong Azure context, unsupported regions, or local script structure issues.

.PARAMETER EnvironmentName
Target environment name. Accepted values: dev, test, prod.

.PARAMETER Location
Azure region used for the deployment.

.PARAMETER SubscriptionId
Expected Azure subscription ID for the deployment run.

.PARAMETER ModulesPath
Local path that must exist before orchestration continues.

.EXAMPLE
Test-DeploymentPrerequisites `
    -EnvironmentName "dev" `
    -Location "denmarkeast" `
    -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -ModulesPath ".\automation"

.NOTES
This function should run before resource creation starts.
#>

function Test-DeploymentPrerequisites {
    param (
        [string]$AppName,
        [string]$Region,
        [string]$EnvironmentName,
        [string]$Location,
        [string]$MonitoringLocation,
        [string]$SubscriptionId,
        [string]$TenantId,
        [string]$VmSize = "Standard_B1s",
        [string]$ModulesPath
    )

    Write-Host ""
    Write-Host "============================================="
    Write-Host "RUNNING PRE-DEPLOYMENT VALIDATION CHECKS"
    Write-Host "============================================="
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($EnvironmentName)) {
        throw "EnvironmentName parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($AppName)) {
        throw "AppName parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($Region)) {
        throw "Region parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($Location)) {
        throw "Location parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($MonitoringLocation)) {
        throw "MonitoringLocation parameter is missing."
    }

    $normalizedMonitoringLocation = $MonitoringLocation.Trim().ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        throw "SubscriptionId parameter is missing."
    }

    if ([string]::IsNullOrWhiteSpace($TenantId)) {
        throw "TenantId parameter is missing."
    }

    if (-not (Test-Path $ModulesPath)) {
        throw "Modules path not found: $ModulesPath"
    }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw "PowerShell 7+ is required. Current version: $($PSVersionTable.PSVersion)."
    }

    foreach ($command in @("az", "Get-AzContext", "Get-AzResourceProvider", "Get-AzComputeResourceSku")) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Required command '$command' is not available in the current session."
        }
    }

    if (-not (Get-Command Resolve-DeploymentRegionLocation -ErrorAction SilentlyContinue)) {
        throw "Resolve-DeploymentRegionLocation function is not loaded. Ensure DeploymentDefaults.ps1 is loaded before prerequisites."
    }

    if (-not (Get-Command Get-DeploymentNames -ErrorAction SilentlyContinue)) {
        throw "Get-DeploymentNames function is not loaded. Ensure DeploymentNaming.ps1 is loaded before prerequisites."
    }

    $resolved = Resolve-DeploymentRegionLocation -Region $Region -Location $Location
    if ($resolved.Region -ne $Region.ToLowerInvariant()) {
        throw "Resolved region '$($resolved.Region)' does not match provided region '$Region'."
    }

    if ($resolved.Location -ne $Location.ToLowerInvariant()) {
        throw "Resolved location '$($resolved.Location)' does not match provided location '$Location'."
    }

    function ConvertTo-LocationKey {
        param(
            [Parameter(Mandatory = $true)][string]$Value
        )

        return ($Value.Trim().ToLowerInvariant().Replace(" ", ""))
    }

    function Assert-ResourceTypeAvailableInLocation {
        param(
            [Parameter(Mandatory = $true)][string]$ProviderNamespace,
            [Parameter(Mandatory = $true)][string]$ResourceTypeName,
            [Parameter(Mandatory = $true)][string]$TargetLocation,
            [Parameter(Mandatory = $true)][string]$TargetLabel
        )

        $providerMetadata = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction SilentlyContinue
        if (-not $providerMetadata) {
            throw "Could not query provider metadata for '$ProviderNamespace'."
        }

        $resourceTypeMetadata = @($providerMetadata.ResourceTypes | Where-Object {
            $_.ResourceTypeName -eq $ResourceTypeName
        }) | Select-Object -First 1

        if (-not $resourceTypeMetadata) {
            throw "Provider '$ProviderNamespace' does not expose resource type '$ResourceTypeName' in this subscription metadata."
        }

        $supportedLocations = @($resourceTypeMetadata.Locations)
        $targetLocationKey = ConvertTo-LocationKey -Value $TargetLocation
        $supportedLocationKeys = @($supportedLocations | ForEach-Object { ConvertTo-LocationKey -Value $_ })

        if ($supportedLocationKeys -notcontains $targetLocationKey) {
            $sampleSupported = @($supportedLocations | Select-Object -First 10)
            $sampleText = if ($sampleSupported.Count -gt 0) { $sampleSupported -join ", " } else { "none published" }

            throw "Required resource type '$ProviderNamespace/$ResourceTypeName' is not available in $TargetLabel location '$TargetLocation'. Choose a location that supports this resource type. Sample supported locations: $sampleText."
        }
    }

        function Assert-MonitoringLocationSubscriptionEligible {
                param(
                        [Parameter(Mandatory = $true)][string]$TargetLocation
                )

                $suffix = ([Guid]::NewGuid().ToString("N")).Substring(0, 8)
                $validationRgName = "rg-monitor-eligibility-$suffix"
                $workspaceName = "law-monitor-elig-$suffix"
                $appInsightsName = "appi-monitor-elig-$suffix"

                try {
                    $validationTemplateObject = [hashtable]@{
                        '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                        contentVersion = '1.0.0.0'
                        parameters = @{
                            location = @{
                                type = 'string'
                            }
                            workspaceName = @{
                                type = 'string'
                            }
                            appInsightsName = @{
                                type = 'string'
                            }
                        }
                        resources = @(
                            @{
                                type = 'Microsoft.OperationalInsights/workspaces'
                                apiVersion = '2022-10-01'
                                name = "[parameters('workspaceName')]"
                                location = "[parameters('location')]"
                                properties = @{
                                    sku = @{
                                        name = 'PerGB2018'
                                    }
                                    retentionInDays = 30
                                }
                            }
                            @{
                                type = 'Microsoft.Insights/components'
                                apiVersion = '2020-02-02'
                                name = "[parameters('appInsightsName')]"
                                location = "[parameters('location')]"
                                kind = 'web'
                                dependsOn = @(
                                    "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName'))]"
                                )
                                properties = @{
                                    Application_Type = 'web'
                                    WorkspaceResourceId = "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('workspaceName'))]"
                                }
                            }
                        )
                    }

                    if ($validationTemplateObject -isnot [System.Collections.Hashtable]) {
                        throw "Eligibility validation template must be converted to a Hashtable before calling Test-AzResourceGroupDeployment."
                    }

                        $null = New-AzResourceGroup -Name $validationRgName -Location $TargetLocation -Tag @{ purpose = "monitoring-eligibility-validation"; owner = "cloud-org-infra" } -ErrorAction Stop

                        $null = Test-AzResourceGroupDeployment `
                                -ResourceGroupName $validationRgName `
                        -TemplateObject $validationTemplateObject `
                                -TemplateParameterObject @{
                                        location = $TargetLocation
                                        workspaceName = $workspaceName
                                        appInsightsName = $appInsightsName
                                } `
                                -ErrorAction Stop
                }
                catch {
                        $azureErrorMessage = $_.Exception.Message
                        throw "Monitoring location subscription eligibility check failed for '$TargetLocation'. Azure returned: $azureErrorMessage"
                }
                finally {
                        if (Get-AzResourceGroup -Name $validationRgName -ErrorAction SilentlyContinue) {
                                Remove-AzResourceGroup -Name $validationRgName -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                }
        }

    $context = Get-AzContext

    if (-not $context) {
        throw "No active Azure session detected. Run Connect-AzAccount first."
    }

    if ($null -eq $context.Subscription.Id -or $context.Subscription.Id -ne $SubscriptionId) {
        throw "Active Azure subscription does not match expected deployment subscription."
    }

    if ($null -eq $context.Tenant.Id -or $context.Tenant.Id -ne $TenantId) {
        throw "Active Azure tenant does not match expected deployment tenant."
    }

    $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction SilentlyContinue

    if (-not $subscription) {
        throw "Subscription '$SubscriptionId' not found or not accessible."
    }

    if ($subscription.State -ne "Enabled") {
        throw "Subscription '$SubscriptionId' is not enabled. Current state: '$($subscription.State)'."
    }

    $validLocations = @(Get-SupportedDeploymentLocations)

    if ($Location -notin $validLocations) {
        throw "Location '$Location' is not in the approved deployment region list."
    }

    if ($EnvironmentName -notmatch '^(dev|test|prod)$') {
        throw "EnvironmentName must be dev, test, or prod."
    }

    $requiredProviders = @(
        "Microsoft.Network",
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Web",
        "Microsoft.Insights",
        "Microsoft.OperationalInsights",
        "Microsoft.ManagedIdentity",
        "Microsoft.Compute",
        "Microsoft.Authorization"
    )

    foreach ($providerNamespace in $requiredProviders) {
        $provider = Get-AzResourceProvider -ProviderNamespace $providerNamespace -ErrorAction SilentlyContinue

        if (-not $provider) {
            throw "Could not query resource provider '$providerNamespace'."
        }

        if ($provider.RegistrationState -ne "Registered") {
            Write-Host "Registering provider '$providerNamespace'..."
            Register-AzResourceProvider -ProviderNamespace $providerNamespace | Out-Null

            $attempt = 0
            do {
                Start-Sleep -Seconds 5
                $provider = Get-AzResourceProvider -ProviderNamespace $providerNamespace -ErrorAction SilentlyContinue
                $attempt++
            }
            while ($provider.RegistrationState -ne "Registered" -and $attempt -lt 24)

            if ($provider.RegistrationState -ne "Registered") {
                throw "Provider '$providerNamespace' is not registered after waiting. Current state: '$($provider.RegistrationState)'."
            }
        }
    }

    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.Compute" -ResourceTypeName "virtualMachines" -TargetLocation $Location -TargetLabel "workload"

    foreach ($networkResourceType in @(
            "virtualNetworks",
            "networkSecurityGroups",
            "privateEndpoints",
            "networkInterfaces"
        )) {
        Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.Network" -ResourceTypeName $networkResourceType -TargetLocation $Location -TargetLabel "workload"
    }

    foreach ($webResourceType in @("serverfarms", "sites")) {
        Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.Web" -ResourceTypeName $webResourceType -TargetLocation $Location -TargetLabel "workload"
    }

    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.ManagedIdentity" -ResourceTypeName "userAssignedIdentities" -TargetLocation $Location -TargetLabel "workload"
    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.Storage" -ResourceTypeName "storageAccounts" -TargetLocation $Location -TargetLabel "workload"
    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.KeyVault" -ResourceTypeName "vaults" -TargetLocation $Location -TargetLabel "workload"
    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.OperationalInsights" -ResourceTypeName "workspaces" -TargetLocation $normalizedMonitoringLocation -TargetLabel "monitoring"
    Assert-ResourceTypeAvailableInLocation -ProviderNamespace "Microsoft.Insights" -ResourceTypeName "components" -TargetLocation $normalizedMonitoringLocation -TargetLabel "monitoring"
    Assert-MonitoringLocationSubscriptionEligible -TargetLocation $normalizedMonitoringLocation

    $skuCandidates = Get-AzComputeResourceSku -ErrorAction Stop | Where-Object {
        $_.ResourceType -eq "virtualMachines" -and
        $_.Name -eq $VmSize -and
        ($_.Locations -contains $Location)
    }

    if (-not $skuCandidates) {
        throw "VM SKU '$VmSize' is not available in location '$Location' for the current subscription context."
    }

    $restrictedInRegion = $false
    foreach ($sku in $skuCandidates) {
        if ($sku.Restrictions) {
            foreach ($restriction in $sku.Restrictions) {
                if ($restriction.Type -eq "Location" -and $restriction.Values -contains $Location) {
                    $restrictedInRegion = $true
                }
            }
        }
    }

    if ($restrictedInRegion) {
        throw "VM SKU '$VmSize' is restricted in '$Location' for this subscription."
    }

    $names = Get-DeploymentNames -Environment $EnvironmentName -App $AppName -Region $Region -SubscriptionId $SubscriptionId -TenantId $TenantId

    $storageInRg = Get-AzStorageAccount -ResourceGroupName $names.ResourceGroupName -Name $names.StorageAccountName -ErrorAction SilentlyContinue
    if (-not $storageInRg) {
        if (Get-Command Get-AzStorageAccountNameAvailability -ErrorAction SilentlyContinue) {
            $availability = Get-AzStorageAccountNameAvailability -Name $names.StorageAccountName -ErrorAction Stop
            if (-not $availability.NameAvailable) {
                throw "Deterministic storage account name '$($names.StorageAccountName)' is unavailable. Detail: $($availability.Message)"
            }
        }
    }

    $kvInRg = Get-AzKeyVault -VaultName $names.KeyVaultName -ResourceGroupName $names.ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $kvInRg) {
        if (Get-Command Test-AzKeyVaultNameAvailability -ErrorAction SilentlyContinue) {
            $kvAvailability = Test-AzKeyVaultNameAvailability -Name $names.KeyVaultName -ErrorAction Stop
            if (-not $kvAvailability.NameAvailable) {
                throw "Deterministic Key Vault name '$($names.KeyVaultName)' is unavailable. Detail: $($kvAvailability.Message)"
            }
        }
    }

    Write-Host "Enterprise pre-deployment validation gate passed successfully." -ForegroundColor Green
}
