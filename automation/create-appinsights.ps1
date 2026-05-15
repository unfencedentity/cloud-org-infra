[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,

    [Parameter(Mandatory = $false)][string]$ApplicationType = "web"
)

$ErrorActionPreference = "Stop"

$rgName = "rg-$App-$Environment-$Region"
$appInsightsName = "appi-$App-$Environment-$Region"

Disable-AzContextAutosave -Scope Process | Out-Null

if ([string]::IsNullOrWhiteSpace($env:AZURE_SUBSCRIPTION_ID)) {
    throw "AZURE_SUBSCRIPTION_ID environment variable is missing or empty."
}

$subscriptionId = $env:AZURE_SUBSCRIPTION_ID.Trim()

Write-Host "Setting Az context for Application Insights deployment..."
Set-AzContext -SubscriptionId $subscriptionId | Out-Null

$currentContext = Get-AzContext

if (-not $currentContext) {
    throw "No active Az PowerShell context found after Set-AzContext."
}

if ($currentContext.Subscription.Id -ne $subscriptionId) {
    throw "Az context subscription mismatch. Expected '$subscriptionId' but got '$($currentContext.Subscription.Id)'."
}

Write-Host ("Using subscription: {0}" -f $currentContext.Subscription.Id)

$provider = Get-AzResourceProvider -ProviderNamespace Microsoft.Insights

if ($provider.RegistrationState -ne "Registered") {
    Write-Host "Microsoft.Insights provider is not registered. Registering now..."

    Register-AzResourceProvider -ProviderNamespace Microsoft.Insights | Out-Null

    do {
        Start-Sleep -Seconds 10

        $provider = Get-AzResourceProvider `
            -ProviderNamespace Microsoft.Insights

        Write-Host ("Microsoft.Insights registration state: {0}" -f `
            $provider.RegistrationState)
    }
    while ($provider.RegistrationState -ne "Registered")

    Write-Host "Microsoft.Insights provider registered."
}

$tags = @{
    environment = $Environment
    app         = $App
    region      = $Region
    owner       = "cloud-org-infra"
}

$rg = Get-AzResourceGroup `
    -Name $rgName `
    -ErrorAction SilentlyContinue

if (-not $rg) {
    throw "Resource group '$rgName' does not exist. Run create-rg.ps1 first."
}

$existing = Get-AzApplicationInsights `
    -ResourceGroupName $rgName `
    -Name $appInsightsName `
    -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host ("Application Insights '{0}' already exists in resource group '{1}'. Skipping create." -f `
        $appInsightsName, $rgName)

    return $existing
}

if (-not $PSCmdlet.ShouldProcess("Application Insights $appInsightsName", "Create")) {
    return
}

Write-Host ("Creating Application Insights '{0}' in '{1}'..." -f `
    $appInsightsName, $Location)

$appInsights = New-AzApplicationInsights `
    -ResourceGroupName $rgName `
    -Name $appInsightsName `
    -Location $Location `
    -Kind "web" `
    -ApplicationType $ApplicationType `
    -Tag $tags

Write-Host ("Application Insights '{0}' created." -f `
    $appInsightsName)

return $appInsights
