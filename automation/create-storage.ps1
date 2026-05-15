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

    $storageAccountResourceId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"

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

    Write-Host ("Creating storage account '{0}' in '{1}' using Azure REST API..." -f `
        $storageAccountName, $Location)

    $response = Invoke-AzRestMethod `
        -Method PUT `
        -Path $storageAccountResourceId `
        -ApiVersion "2023-01-01" `
        -PayloadJson $storageAccountBody

    if ($response.StatusCode -notin @(200, 201, 202)) {
        throw "Storage account deployment failed. StatusCode: $($response.StatusCode). Content: $($response.Content)"
    }

    Write-Host ("Storage account '{0}' deployment submitted." -f $storageAccountName)

    do {
        Start-Sleep -Seconds 10

        $sa = Get-AzStorageAccount `
            -ResourceGroupName $rgName `
            -Name $storageAccountName `
            -ErrorAction SilentlyContinue

        if ($sa) {
            Write-Host ("Storage account '{0}' is now available." -f $storageAccountName)
            break
        }

        Write-Host ("Waiting for storage account '{0}' to become available..." -f $storageAccountName)
    }
    while (-not $sa)

    if (-not $sa) {
        throw "Storage account '$storageAccountName' was submitted but could not be retrieved."
    }
}

if ($Containers -and $Containers.Count -gt 0) {
    $ctx = $sa.Context

    foreach ($containerName in $Containers) {
        $existingContainer = Get-AzStorageContainer `
            -Context $ctx `
            -Name $containerName `
            -ErrorAction SilentlyContinue

        if ($existingContainer) {
            Write-Host ("Container '{0}' already exists in storage account '{1}'. Skipping." -f `
                $containerName, $storageAccountName)

            continue
        }

        if (-not $PSCmdlet.ShouldProcess("Container $containerName", "Create")) {
            continue
        }

        Write-Host ("Creating blob container '{0}' in storage account '{1}'..." -f `
            $containerName, $storageAccountName)

        New-AzStorageContainer `
            -Context $ctx `
            -Name $containerName `
            -Permission Off | Out-Null
    }
}

return $sa
