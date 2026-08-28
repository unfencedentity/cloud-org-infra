Set-StrictMode -Version Latest

function Get-DeploymentSubscriptionId {
    param(
        [string]$SubscriptionId
    )

    if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
        return $SubscriptionId.Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($env:AZURE_SUBSCRIPTION_ID)) {
        return $env:AZURE_SUBSCRIPTION_ID.Trim()
    }

    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if ($ctx -and $ctx.Subscription -and $ctx.Subscription.Id) {
        return $ctx.Subscription.Id
    }

    throw "Unable to resolve deployment subscription id from parameter, AZURE_SUBSCRIPTION_ID, or current Az context."
}

function Get-DeploymentTenantId {
    param(
        [string]$TenantId
    )

    if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
        return $TenantId.Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($env:AZURE_TENANT_ID)) {
        return $env:AZURE_TENANT_ID.Trim()
    }

    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if ($ctx -and $ctx.Tenant -and $ctx.Tenant.Id) {
        return $ctx.Tenant.Id
    }

    throw "Unable to resolve deployment tenant id from parameter, AZURE_TENANT_ID, or current Az context."
}

function Get-DeterministicHash {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 64)]
        [int]$Length
    )

    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($Value)
    )

    return ([System.BitConverter]::ToString($hashBytes)).
        Replace("-", "").
        Substring(0, $Length).
        ToLowerInvariant()
}

function Get-DeploymentNames {
    param(
        [Parameter(Mandatory = $true)][string]$Environment,
        [Parameter(Mandatory = $true)][string]$App,
        [Parameter(Mandatory = $true)][string]$Region,
        [string]$SubscriptionId,
        [string]$TenantId
    )

    $resolvedSubscriptionId = Get-DeploymentSubscriptionId -SubscriptionId $SubscriptionId
    $resolvedTenantId = Get-DeploymentTenantId -TenantId $TenantId

    $resourceGroupName = "rg-$App-$Environment-$Region"
    $coreVnetName = "vnet-$App-$Environment-$Region"
    $hubVnetName = "vnet-hub-$Environment-$Region"
    $nsgName = "nsg-$App-$Environment-$Region"
    $managedIdentityName = "mi-$App-$Environment-$Region"
    $appServicePlanName = "asp-$App-$Environment-$Region"
    $logAnalyticsName = "law-$App-$Environment-$Region"
    $appInsightsName = "appi-$App-$Environment-$Region"
    $privateEndpointName = "pe-storage-$Environment-$Region"
    $vmName = "vm-$App-$Environment-$Region-01"

    $webAppHash = Get-DeterministicHash -Value "$App-$Environment-$Region-$resolvedSubscriptionId" -Length 10
    $webAppName = ("app-$App-$Environment-$Region-$webAppHash").ToLowerInvariant().Replace("-", "")

    $storageHash = Get-DeterministicHash -Value "$resolvedSubscriptionId-$App-$Environment-$Region" -Length 6
    $storageAccountName = ("st$App$Environment$Region$storageHash").ToLowerInvariant().Replace("-", "")

    $keyVaultHash = Get-DeterministicHash -Value "$resolvedSubscriptionId-$App-$Environment-$Region" -Length 6
    $keyVaultName = ("kv$App$Environment$Region$keyVaultHash").ToLowerInvariant().Replace("-", "")

    return [PSCustomObject]@{
        SubscriptionId      = $resolvedSubscriptionId
        TenantId            = $resolvedTenantId
        ResourceGroupName   = $resourceGroupName
        CoreVNetName        = $coreVnetName
        HubVNetName         = $hubVnetName
        NsgName             = $nsgName
        ManagedIdentityName = $managedIdentityName
        AppServicePlanName  = $appServicePlanName
        LogAnalyticsName    = $logAnalyticsName
        AppInsightsName     = $appInsightsName
        WebAppName          = $webAppName
        StorageAccountName  = $storageAccountName
        KeyVaultName        = $keyVaultName
        PrivateEndpointName = $privateEndpointName
        VmName              = $vmName
    }
}
