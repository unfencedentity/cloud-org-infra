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

if (-not $env:AZURE_SUBSCRIPTION_ID) {
    throw "AZURE_SUBSCRIPTION_ID environment variable is missing."
}

$subscriptionId = $env:AZURE_SUBSCRIPTION_ID

Set-AzContext -SubscriptionId $subscriptionId | Out-Null

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

    Write-Host ("Creating storage account '{0}' in '{1}'..." -f $storageAccountName, $Location)

    $sa = New-AzStorageAccount `
        -Name $storageAccountName `
        -ResourceGroupName $rgName `
        -Location $Location `
        -SkuName $SkuName `
        -Kind $Kind `
        -AccessTier $AccessTier `
        -EnableHttpsTrafficOnly $true `
        -Tag $tags

    Write-Host ("Storage account '{0}' created." -f $storageAccountName)
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
