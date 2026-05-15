[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$SkuName = "Standard_LRS",
    [Parameter(Mandatory = $false)][string]$Kind = "StorageV2",
    [Parameter(Mandatory = $false)][string]$AccessTier = "Hot",

    [Parameter(Mandatory = $false)][string[]]$Containers = @("logs", "apps", "data")
)

$ErrorActionPreference = "Stop"

$rgName = "rg-$App-$Environment-$Region"

if ([string]::IsNullOrWhiteSpace($env:AZURE_SUBSCRIPTION_ID)) {
    throw "AZURE_SUBSCRIPTION_ID environment variable is missing or empty."
}

$subscriptionId = $env:AZURE_SUBSCRIPTION_ID.Trim()

Disable-AzContextAutosave -Scope Process | Out-Null

Write-Host "Setting Az context for storage deployment..."
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

$currentContext = Get-AzContext

if (-not $currentContext) {
    throw "No active Az PowerShell context found after Set-AzContext."
}

if ($currentContext.Subscription.Id -ne $subscriptionId) {
    throw "Az context subscription mismatch. Expected '$subscriptionId' but got '$($currentContext.Subscription.Id)'."
}

Write-Host ("Using subscription: {0}" -f $currentContext.Subscription.Id)

$provider = Get-AzResourceProvider -ProviderNamespace Microsoft.Storage

if ($provider.RegistrationState -ne "Registered") {
    Write-Host "Microsoft.Storage provider is not registered. Registering now..."

    Register-AzResourceProvider -ProviderNamespace Microsoft.Storage | Out-Null

    do {
        Start-Sleep -Seconds 10
        $provider = Get-AzResourceProvider -ProviderNamespace Microsoft.Storage
        Write-Host ("Microsoft.Storage registration state: {0}" -f $provider.RegistrationState)
    }
    while ($provider.RegistrationState -ne "Registered")

    Write-Host "Microsoft.Storage provider registered."
}

$baseString = "$subscriptionId-$App-$Environment-$Region"

$hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($baseString)
)

$hash = ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").Substring(0, 6).ToLower()

$storageAccountName = "st$App$Environment$Region$hash"
$storageAccountName = $storageAccountName.ToLower().Replace("-", "")

$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue

if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

$tokenResponse = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"

if ($tokenResponse.Token -is [System.Security.SecureString]) {
    $accessToken = [System.Net.NetworkCredential]::new("", $tokenResponse.Token).Password
}
else {
    $accessToken = [string]$tokenResponse.Token
}

if ([string]::IsNullOrWhiteSpace($accessToken)) {
    throw "Failed to retrieve Azure access token."
}

$headers = @{
    Authorization  = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

$storageAccountUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageAccountName" + "?api-version=2023-01-01"

$existing = Get-AzStorageAccount `
    -ResourceGroupName $rgName `
    -Name $storageAccountName `
    -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host ("Storage account '{0}' already exists in resource group '{1}'. Skipping create." -f `
        $storageAccountName, $rgName)

    $sa = $existing
}
else {
    if (-not $PSCmdlet.ShouldProcess("Storage account $storageAccountName", "Create")) {
        return
    }

    Write-Host ("Creating storage account '{0}' in '{1}' using Azure Resource Manager REST API..." -f `
        $storageAccountName, $Location)

    $storageAccountBody = @{
        location   = $Location
        sku        = @{
            name = $SkuName
        }
        kind       = $Kind
        properties = @{
            accessTier               = $AccessTier
            supportsHttpsTrafficOnly = $true
            minimumTlsVersion        = "TLS1_2"
            allowBlobPublicAccess    = $false
        }
        tags       = $tags
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod `
        -Method Put `
        -Uri $storageAccountUri `
        -Headers $headers `
        -Body $storageAccountBody | Out-Null

    Write-Host ("Storage account '{0}' deployment submitted." -f $storageAccountName)
}

do {
    Start-Sleep -Seconds 10

    $storageState = Invoke-RestMethod `
        -Method Get `
        -Uri $storageAccountUri `
        -Headers $headers

    $provisioningState = $storageState.properties.provisioningState

    Write-Host ("Storage account '{0}' provisioning state: {1}" -f `
        $storageAccountName, $provisioningState)
}
while ($provisioningState -ne "Succeeded")

$sa = Get-AzStorageAccount `
    -ResourceGroupName $rgName `
    -Name $storageAccountName `
    -ErrorAction Stop

Write-Host ("Storage account '{0}' is fully provisioned." -f $storageAccountName)

if ($Containers -and $Containers.Count -gt 0) {
    foreach ($containerName in $Containers) {
        $containerUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/blobServices/default/containers/$containerName" + "?api-version=2023-01-01"

        if (-not $PSCmdlet.ShouldProcess("Container $containerName", "Create or update")) {
            continue
        }

        Write-Host ("Creating or updating blob container '{0}' in storage account '{1}' using Azure Resource Manager REST API..." -f `
            $containerName, $storageAccountName)

        $containerBody = @{
            properties = @{
                publicAccess = "None"
            }
        } | ConvertTo-Json -Depth 10

        Invoke-RestMethod `
            -Method Put `
            -Uri $containerUri `
            -Headers $headers `
            -Body $containerBody | Out-Null

        Write-Host ("Container '{0}' is configured." -f $containerName)
    }
}

return $sa
