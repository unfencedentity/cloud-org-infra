
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Environment,
    [Parameter(Mandatory = $true)][string]$App,
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Location,
    [Parameter(Mandatory = $false)][string]$MonitoringLocation
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\shared\ObjectShape.ps1"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "          Azure Environment Health Check - Standard Scan" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment | App: $App | Region: $Region | Location: $Location"
if (-not [string]::IsNullOrWhiteSpace($MonitoringLocation)) {
    Write-Host "Monitoring Location: $MonitoringLocation"
}
Write-Host ""

$HealthResults = @()
$GlobalScore = 100

function Add-HealthResult {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Details,
        [int]$ScoreImpact
    )

    $result = [PSCustomObject]@{
        Name        = $Name
        Status      = $Status
        Details     = $Details
        ScoreImpact = $ScoreImpact
    }

    $script:HealthResults += $result
    $script:GlobalScore -= $ScoreImpact
}

function Write-Status {
    param([string]$Message, [string]$Level)

    switch ($Level.ToUpper()) {
        "OK"       { Write-Host "[OK]       $Message" -ForegroundColor Green }
        "WARNING"  { Write-Host "[WARNING]  $Message" -ForegroundColor Yellow }
        "CRITICAL" { Write-Host "[CRITICAL] $Message" -ForegroundColor Red }
        default     { Write-Host "[INFO]     $Message" -ForegroundColor White }
    }
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Get-RG {
    $rgName = "rg-$App-$Environment-$Region"
    return Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
}

function Get-VNet {
    $vnetName = "vnet-$App-$Environment-$Region"
    $rg = Get-RG

    if (-not $rg) {
        return $null
    }

    return Get-AzVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
}

function Get-NSGs {
    $rg = Get-RG

    if (-not $rg) {
        return @()
    }

    return Get-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
}

function Get-StorageAccounts {
    $rg = Get-RG

    if (-not $rg) {
        return @()
    }

    return Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
}

function Get-KeyVault {
    $kvPrefix = "kv$App$Environment$Region"
    $rg = Get-RG

    if (-not $rg) {
        return $null
    }

    $vaults = @(Get-AzKeyVault -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue)

    $matchedVaultSummary = $vaults | Where-Object {
        $vaultName = Get-ObjectPropertyValue -Object $_ -PropertyName "VaultName"
        -not [string]::IsNullOrWhiteSpace($vaultName) -and $vaultName -like "$kvPrefix*"
    } | Select-Object -First 1

    if (-not $matchedVaultSummary) {
        return [PSCustomObject]@{
            State            = "Missing"
            ResourceGroupName = $rg.ResourceGroupName
            VaultName        = $null
            Vault            = $null
        }
    }

    $matchedVaultName = Get-ObjectPropertyValue -Object $matchedVaultSummary -PropertyName "VaultName"

    if ([string]::IsNullOrWhiteSpace($matchedVaultName)) {
        return [PSCustomObject]@{
            State            = "DiscoveryShapeInvalid"
            ResourceGroupName = $rg.ResourceGroupName
            VaultName        = $null
            Vault            = $null
        }
    }

    $detailedVault = Get-AzKeyVault `
        -ResourceGroupName $rg.ResourceGroupName `
        -VaultName $matchedVaultName `
        -ErrorAction SilentlyContinue

    if (-not $detailedVault) {
        return [PSCustomObject]@{
            State            = "DetailsUnavailable"
            ResourceGroupName = $rg.ResourceGroupName
            VaultName        = $matchedVaultName
            Vault            = $null
        }
    }

    return [PSCustomObject]@{
        State            = "Found"
        ResourceGroupName = $rg.ResourceGroupName
        VaultName        = $matchedVaultName
        Vault            = $detailedVault
    }
}

function Get-AppService {
    $appPrefix = "app$App$Environment$Region"
    $rg = Get-RG

    if (-not $rg) {
        return $null
    }

    $apps = Get-AzWebApp -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue

    return $apps | Where-Object {
        $_.Name -like "$appPrefix*"
    } | Select-Object -First 1
}

function Get-AppInsights {
    $rg = Get-RG
    $aiName = "appi-$App-$Environment-$Region"

    if (-not $rg) {
        return $null
    }

    return Get-AzApplicationInsights -ResourceGroupName $rg.ResourceGroupName -Name $aiName -ErrorAction SilentlyContinue
}

function Get-DiagnosticSettingsRest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceId
    )

    try {
        $uri = "https://management.azure.com$ResourceId/providers/microsoft.insights/diagnosticSettings?api-version=2021-05-01-preview"
        $response = Invoke-AzRestMethod -Method GET -Uri $uri

        $statusCode = Get-ObjectPropertyValue -Object $response -PropertyName "StatusCode" -DefaultValue 0
        if ($statusCode -lt 200 -or $statusCode -ge 300) {
            return @()
        }

        $rawContent = Get-ObjectPropertyValue -Object $response -PropertyName "Content"
        if ([string]::IsNullOrWhiteSpace($rawContent)) {
            return @()
        }

        $content = $rawContent | ConvertFrom-Json

        if (-not $content.value) {
            return @()
        }

        return @($content.value)
    }
    catch {
        Write-Warning "Could not read diagnostic settings for resource [$ResourceId]. Error: $($_.Exception.Message)"
        return @()
    }
}

function Test-DiagnosticSettingExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceId,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedDiagnosticName
    )

    $settings = Get-DiagnosticSettingsRest -ResourceId $ResourceId

    if (@($settings).Count -eq 0) {
        return $false
    }

    $match = $settings | Where-Object {
        $_.name -eq $ExpectedDiagnosticName
    } | Select-Object -First 1

    return $null -ne $match
}

function Get-Severity {
    param([int]$Score)

    if ($Score -ge 90) { return "OK" }
    if ($Score -ge 70) { return "Warning" }
    return "Critical"
}

function Resolve-ResourceId {
    param(
        [Parameter(Mandatory = $false)]$Object
    )

    $resourceId = Get-ObjectPropertyValue -Object $Object -PropertyName "Id"
    if ([string]::IsNullOrWhiteSpace($resourceId)) {
        $resourceId = Get-ObjectPropertyValue -Object $Object -PropertyName "ResourceId"
    }

    return $resourceId
}

function Resolve-Name {
    param(
        [Parameter(Mandatory = $false)]$Object,
        [string]$DefaultValue = "unknown"
    )

    $name = Get-ObjectPropertyValue -Object $Object -PropertyName "Name"
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = Get-ObjectPropertyValue -Object $Object -PropertyName "StorageAccountName"
    }
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = Get-ObjectPropertyValue -Object $Object -PropertyName "VaultName"
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
        return $DefaultValue
    }

    return $name
}

Write-Host "Initializing resource discovery..." -ForegroundColor DarkGray

$ResourceGroup = Get-RG
$VirtualNetwork = Get-VNet
$NSGs = @(Get-NSGs)
$StorageAccounts = @(Get-StorageAccounts)
$KeyVaultLookup = Get-KeyVault
$KeyVault = Get-ObjectPropertyValue -Object $KeyVaultLookup -PropertyName "Vault"
$AppService = Get-AppService
$AppInsights = Get-AppInsights

Write-Host "Resource discovery complete." -ForegroundColor DarkGray

Write-Section "Resource Group"

if (-not $ResourceGroup) {
    Write-Status "Resource Group not found" "CRITICAL"
    Add-HealthResult -Name "ResourceGroup" -Status "CRITICAL" -Details "Resource group missing" -ScoreImpact 25
} else {
    Write-Status "Resource Group exists: $($ResourceGroup.ResourceGroupName)" "OK"
    Add-HealthResult -Name "ResourceGroup" -Status "OK" -Details "RG present" -ScoreImpact 0
}

Write-Section "Tags"

$requiredTags = @("environment", "app", "region", "owner")
$missingTags = @()

$resourceGroupTags = Get-ObjectPropertyValue -Object $ResourceGroup -PropertyName "Tags"

if ($ResourceGroup -and $resourceGroupTags -is [System.Collections.IDictionary]) {
    foreach ($tag in $requiredTags) {
        if (-not $resourceGroupTags.ContainsKey($tag)) {
            $missingTags += $tag
        }
    }
} else {
    $missingTags = $requiredTags
}

if (@($missingTags).Count -gt 0) {
    Write-Status "Missing tags: $($missingTags -join ', ')" "WARNING"
    Add-HealthResult -Name "Tags" -Status "WARNING" -Details "Missing: $($missingTags -join ', ')" -ScoreImpact 10
} else {
    Write-Status "All required tags present" "OK"
    Add-HealthResult -Name "Tags" -Status "OK" -Details "Tags valid" -ScoreImpact 0
}

Write-Section "Virtual Network"

if (-not $VirtualNetwork) {
    Write-Status "VNet not found" "CRITICAL"
    Add-HealthResult -Name "VNet" -Status "CRITICAL" -Details "VNet missing" -ScoreImpact 20
} else {
    $vnetNameDisplay = Resolve-Name -Object $VirtualNetwork -DefaultValue "unnamed-vnet"
    Write-Status "VNet found: $vnetNameDisplay" "OK"
    Add-HealthResult -Name "VNet" -Status "OK" -Details "VNet present" -ScoreImpact 0
}

Write-Section "Subnets"

$vnetSubnets = @()
if ($VirtualNetwork) {
    $vnetSubnets = @(Get-ObjectPropertyValue -Object $VirtualNetwork -PropertyName "Subnets" -DefaultValue @())
}

if ($VirtualNetwork -and @($vnetSubnets).Count -gt 0) {
    Write-Status "Subnets found: $(@($vnetSubnets).Count)" "OK"
    Add-HealthResult -Name "Subnets" -Status "OK" -Details "Subnets OK" -ScoreImpact 0
} else {
    Write-Status "No subnets found" "CRITICAL"
    Add-HealthResult -Name "Subnets" -Status "CRITICAL" -Details "Missing subnets" -ScoreImpact 15
}

Write-Section "Network Security Groups"

if (@($NSGs).Count -gt 0) {
    Write-Status "NSGs found: $(@($NSGs).Count)" "OK"
    Add-HealthResult -Name "NSG" -Status "OK" -Details "NSGs OK" -ScoreImpact 0
} else {
    Write-Status "No NSGs found" "CRITICAL"
    Add-HealthResult -Name "NSG" -Status "CRITICAL" -Details "NSGs missing" -ScoreImpact 15
}

Write-Section "Storage Accounts"

if (@($StorageAccounts).Count -eq 0) {
    Write-Status "No Storage Accounts found" "WARNING"
    Add-HealthResult -Name "Storage" -Status "WARNING" -Details "Missing storage accounts" -ScoreImpact 10
} else {
    foreach ($st in $StorageAccounts) {
        $storageName = Resolve-Name -Object $st -DefaultValue "unknown-storage"
        $httpsOnlyEnabled = Get-ObjectPropertyValue -Object $st -PropertyName "EnableHttpsTrafficOnly"

        if ($null -eq $httpsOnlyEnabled) {
            Write-Status "Unable to verify HTTPS enforcement on $storageName" "WARNING"
            Add-HealthResult -Name "StorageSecurity" -Status "WARNING" -Details "HTTPS enforcement property unavailable on $storageName" -ScoreImpact 5
        } elseif ($httpsOnlyEnabled -eq $false) {
            Write-Status "HTTPS not enforced on $storageName" "CRITICAL"
            Add-HealthResult -Name "StorageSecurity" -Status "CRITICAL" -Details "HTTPS disabled on $storageName" -ScoreImpact 20
        } else {
            Write-Status "HTTPS enforced on $storageName" "OK"
        }
    }

    Add-HealthResult -Name "Storage" -Status "OK" -Details "Security validated" -ScoreImpact 0
}

Write-Section "Key Vault"

if (-not $KeyVaultLookup -or (Get-ObjectPropertyValue -Object $KeyVaultLookup -PropertyName "State") -eq "Missing") {
    Write-Status "Key Vault not found" "CRITICAL"
    Add-HealthResult -Name "KeyVault" -Status "CRITICAL" -Details "KV missing" -ScoreImpact 20
} elseif ((Get-ObjectPropertyValue -Object $KeyVaultLookup -PropertyName "State") -eq "DetailsUnavailable") {
    $discoveryName = Get-ObjectPropertyValue -Object $KeyVaultLookup -PropertyName "VaultName" -DefaultValue "unknown"
    Write-Status "Key Vault details query failed for $discoveryName" "WARNING"
    Add-HealthResult -Name "KeyVault" -Status "WARNING" -Details "KV details query failed for $discoveryName" -ScoreImpact 10
} elseif ((Get-ObjectPropertyValue -Object $KeyVaultLookup -PropertyName "State") -eq "DiscoveryShapeInvalid") {
    Write-Status "Key Vault discovery returned an unexpected object shape" "WARNING"
    Add-HealthResult -Name "KeyVault" -Status "WARNING" -Details "KV discovery object shape invalid" -ScoreImpact 10
} elseif (-not $KeyVault) {
    Write-Status "Key Vault details unavailable" "WARNING"
    Add-HealthResult -Name "KeyVault" -Status "WARNING" -Details "KV details unavailable" -ScoreImpact 10
} else {
    $hasPurgeProtectionProperty = Test-ObjectProperty -Object $KeyVault -PropertyName "EnablePurgeProtection"
    if (-not $hasPurgeProtectionProperty) {
        Write-Status "Purge protection property unavailable on Key Vault details" "WARNING"
        Add-HealthResult -Name "KeyVault" -Status "WARNING" -Details "Purge protection property unavailable" -ScoreImpact 5
    } else {
        $purgeProtectionEnabled = Get-ObjectPropertyValue -Object $KeyVault -PropertyName "EnablePurgeProtection"
        if ($purgeProtectionEnabled -ne $true) {
            Write-Status "Purge protection DISABLED" "WARNING"
            Add-HealthResult -Name "KeyVault" -Status "WARNING" -Details "Purge protection disabled" -ScoreImpact 5
        } else {
            Write-Status "Purge protection enabled" "OK"
            Add-HealthResult -Name "KeyVault" -Status "OK" -Details "Secure" -ScoreImpact 0
        }
    }
}

Write-Section "App Service"

if (-not $AppService) {
    Write-Status "App Service missing" "CRITICAL"
    Add-HealthResult -Name "AppService" -Status "CRITICAL" -Details "Missing" -ScoreImpact 20
} else {
    $appServiceName = Resolve-Name -Object $AppService -DefaultValue "unknown-appservice"
    $appServiceHttpsOnly = Get-ObjectPropertyValue -Object $AppService -PropertyName "HttpsOnly"
    if ($null -eq $appServiceHttpsOnly) {
        Write-Status "HTTPS property unavailable for App Service $appServiceName" "WARNING"
        Add-HealthResult -Name "AppService" -Status "WARNING" -Details "HTTPS property unavailable" -ScoreImpact 5
    } elseif ($appServiceHttpsOnly -eq $false) {
        Write-Status "HTTPS disabled for App Service" "WARNING"
        Add-HealthResult -Name "AppService" -Status "WARNING" -Details "HTTPS disabled" -ScoreImpact 10
    } else {
        Write-Status "App Service HTTPS enforced" "OK"
        Add-HealthResult -Name "AppService" -Status "OK" -Details "Secure" -ScoreImpact 0
    }
}

Write-Section "Application Insights"

if (-not $AppInsights) {
    Write-Status "App Insights missing" "WARNING"
    Add-HealthResult -Name "AppInsights" -Status "WARNING" -Details "Missing" -ScoreImpact 10
} else {
    Write-Status "App Insights present" "OK"
    Add-HealthResult -Name "AppInsights" -Status "OK" -Details "Connected" -ScoreImpact 0
}

Write-Section "Diagnostics"

$diagnosticChecks = @()

$virtualNetworkId = Resolve-ResourceId -Object $VirtualNetwork
if ($VirtualNetwork -and -not [string]::IsNullOrWhiteSpace($virtualNetworkId)) {
    $vnetDiagnosticName = "diag-$(Resolve-Name -Object $VirtualNetwork -DefaultValue 'vnet')"
    $diagnosticChecks += [PSCustomObject]@{
        Name           = "VNet"
        ResourceId     = $virtualNetworkId
        DiagnosticName = $vnetDiagnosticName
    }
}

$keyVaultResourceId = Resolve-ResourceId -Object $KeyVault
if ($KeyVault -and -not [string]::IsNullOrWhiteSpace($keyVaultResourceId)) {
    $keyVaultDiagnosticName = "diag-$(Resolve-Name -Object $KeyVault -DefaultValue 'keyvault')"
    $diagnosticChecks += [PSCustomObject]@{
        Name           = "KeyVault"
        ResourceId     = $keyVaultResourceId
        DiagnosticName = $keyVaultDiagnosticName
    }
}

$appServiceResourceId = Resolve-ResourceId -Object $AppService
if ($AppService -and -not [string]::IsNullOrWhiteSpace($appServiceResourceId)) {
    $appServiceDiagnosticName = "diag-$(Resolve-Name -Object $AppService -DefaultValue 'appservice')"
    $diagnosticChecks += [PSCustomObject]@{
        Name           = "AppService"
        ResourceId     = $appServiceResourceId
        DiagnosticName = $appServiceDiagnosticName
    }
}

foreach ($st in $StorageAccounts) {
    $storageResourceId = Resolve-ResourceId -Object $st
    if ($st -and -not [string]::IsNullOrWhiteSpace($storageResourceId)) {
        $storageDiagnosticName = "diag-$(Resolve-Name -Object $st -DefaultValue 'storage')"
        $diagnosticChecks += [PSCustomObject]@{
            Name           = "Storage"
            ResourceId     = $storageResourceId
            DiagnosticName = $storageDiagnosticName
        }
    }
}

$missingDiagnostics = @()

foreach ($check in $diagnosticChecks) {
    $exists = Test-DiagnosticSettingExists -ResourceId $check.ResourceId -ExpectedDiagnosticName $check.DiagnosticName

    if ($exists) {
        Write-Status "Diagnostics found: $($check.DiagnosticName)" "OK"
    } else {
        Write-Status "Diagnostics missing: $($check.DiagnosticName)" "WARNING"
        $missingDiagnostics += $check.Name
    }
}

if (@($diagnosticChecks).Count -eq 0) {
    Write-Status "No diagnostic targets found" "WARNING"
    Add-HealthResult -Name "Diagnostics" -Status "WARNING" -Details "No diagnostic targets found" -ScoreImpact 10
} elseif (@($missingDiagnostics).Count -gt 0) {
    Add-HealthResult -Name "Diagnostics" -Status "WARNING" -Details "$(@($missingDiagnostics).Count) resources missing diagnostics: $($missingDiagnostics -join ', ')" -ScoreImpact 10
} else {
    Add-HealthResult -Name "Diagnostics" -Status "OK" -Details "All expected diagnostics configured" -ScoreImpact 0
    Write-Status "All diagnostics correctly configured" "OK"
}

Write-Section "Alerts"

$actionGroupName = "ag-$App-$Environment-$Region"

if ($ResourceGroup) {
    $resourceGroupName = Get-ObjectPropertyValue -Object $ResourceGroup -PropertyName "ResourceGroupName"
    $ag = Get-AzActionGroup -Name $actionGroupName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
} else {
    $ag = $null
}

if (-not $ag) {
    Write-Status "Action Group missing" "WARNING"
    Add-HealthResult -Name "Alerts" -Status "WARNING" -Details "Action group missing" -ScoreImpact 10
} else {
    Write-Status "Action Group found" "OK"
    Add-HealthResult -Name "Alerts" -Status "OK" -Details "Alerts configured" -ScoreImpact 0
}

Write-Section "RBAC"

if ($ResourceGroup) {
    $resourceGroupName = Get-ObjectPropertyValue -Object $ResourceGroup -PropertyName "ResourceGroupName"
    $assignments = @(Get-AzRoleAssignment -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue)
} else {
    $assignments = @()
}

$unexpected = @($assignments | Where-Object {
        $roleDefinitionName = Get-ObjectPropertyValue -Object $_ -PropertyName "RoleDefinitionName"
        $objectId = Get-ObjectPropertyValue -Object $_ -PropertyName "ObjectId"
        $roleDefinitionName -eq "Contributor" -and $objectId -notlike "*"
    })

if (@($unexpected).Count -gt 0) {
    Write-Status "Unexpected Contributor assignments detected" "WARNING"
    Add-HealthResult -Name "RBAC" -Status "WARNING" -Details "Unexpected Contributor roles present" -ScoreImpact 10
} else {
    Write-Status "RBAC assignment structure OK" "OK"
    Add-HealthResult -Name "RBAC" -Status "OK" -Details "RBAC clean" -ScoreImpact 0
}

Write-Section "Private DNS"

$dnsZoneName = "internal.cloudorg.local"
$vnetLinkName = "link-vnet-$App-$Environment-$Region"
$dnsRecordName = "vm-$App-$Environment-$Region"
$vmName = "vm-$Environment-$App-$Region-01"

$dnsWarnings = @()

if (-not $ResourceGroup) {
    Write-Status "Cannot validate DNS because Resource Group is missing" "WARNING"
    $dnsWarnings += "Resource Group missing"
}
else {
    $resourceGroupName = Get-ObjectPropertyValue -Object $ResourceGroup -PropertyName "ResourceGroupName"
    $dnsZone = Get-AzPrivateDnsZone `
        -ResourceGroupName $resourceGroupName `
        -Name $dnsZoneName `
        -ErrorAction SilentlyContinue

    if (-not $dnsZone) {
        Write-Status "Private DNS Zone missing: $dnsZoneName" "WARNING"
        $dnsWarnings += "Private DNS Zone missing"
    }
    else {
        Write-Status "Private DNS Zone present: $dnsZoneName" "OK"

        $vnetLink = Get-AzPrivateDnsVirtualNetworkLink `
            -ResourceGroupName $resourceGroupName `
            -ZoneName $dnsZoneName `
            -Name $vnetLinkName `
            -ErrorAction SilentlyContinue

        if (-not $vnetLink) {
            Write-Status "Private DNS VNet link missing: $vnetLinkName" "WARNING"
            $dnsWarnings += "VNet link missing"
        }
        else {
            Write-Status "Private DNS VNet link present: $vnetLinkName" "OK"
        }

        $recordSet = Get-AzPrivateDnsRecordSet `
            -ResourceGroupName $resourceGroupName `
            -ZoneName $dnsZoneName `
            -Name $dnsRecordName `
            -RecordType A `
            -ErrorAction SilentlyContinue

        if (-not $recordSet) {
            Write-Status "Private DNS A record missing: $dnsRecordName.$dnsZoneName" "WARNING"
            $dnsWarnings += "A record missing"
        }
        else {
            Write-Status "Private DNS A record present: $dnsRecordName.$dnsZoneName" "OK"

            $vm = Get-AzVM `
                -ResourceGroupName $resourceGroupName `
                -Name $vmName `
                -ErrorAction SilentlyContinue

            if ($vm) {
                $networkProfile = Get-ObjectPropertyValue -Object $vm -PropertyName "NetworkProfile"
                $networkInterfaces = Get-ObjectPropertyValue -Object $networkProfile -PropertyName "NetworkInterfaces" -DefaultValue @()
                $firstNetworkInterface = Get-FirstCollectionItem -Collection $networkInterfaces
                $nicId = Get-ObjectPropertyValue -Object $firstNetworkInterface -PropertyName "Id"

                if ([string]::IsNullOrWhiteSpace($nicId)) {
                    Write-Status "VM network interface id missing on $vmName" "WARNING"
                    $dnsWarnings += "VM NIC id missing"
                    continue
                }

                $nicName = ($nicId -split "/")[-1]

                $nic = Get-AzNetworkInterface `
                    -ResourceGroupName $resourceGroupName `
                    -Name $nicName `
                    -ErrorAction SilentlyContinue

                if (-not $nic) {
                    Write-Status "NIC not found for VM: $nicName" "WARNING"
                    $dnsWarnings += "NIC missing"
                    continue
                }

                $ipConfigurations = Get-ObjectPropertyValue -Object $nic -PropertyName "IpConfigurations" -DefaultValue @()
                $firstIpConfiguration = Get-FirstCollectionItem -Collection $ipConfigurations
                $privateIp = Get-ObjectPropertyValue -Object $firstIpConfiguration -PropertyName "PrivateIpAddress"

                $records = @(Get-ObjectPropertyValue -Object $recordSet -PropertyName "Records" -DefaultValue @())
                $firstRecord = Get-FirstCollectionItem -Collection $records
                $dnsIp = Get-ObjectPropertyValue -Object $firstRecord -PropertyName "Ipv4Address"

                if ([string]::IsNullOrWhiteSpace($privateIp) -or [string]::IsNullOrWhiteSpace($dnsIp)) {
                    Write-Status "Unable to compare DNS/VM IP for $dnsRecordName.$dnsZoneName" "WARNING"
                    $dnsWarnings += "DNS IP comparison data missing"
                    continue
                }

                if ($dnsIp -eq $privateIp) {
                    Write-Status "Private DNS A record points to VM private IP: $privateIp" "OK"
                }
                else {
                    Write-Status "Private DNS A record mismatch. DNS=$dnsIp VM=$privateIp" "WARNING"
                    $dnsWarnings += "A record IP mismatch"
                }
            }
        }
    }
}

if (@($dnsWarnings).Count -gt 0) {
    Add-HealthResult -Name "DNS" -Status "WARNING" -Details "$($dnsWarnings -join ', ')" -ScoreImpact 5
}
else {
    Add-HealthResult -Name "DNS" -Status "OK" -Details "Private DNS validated" -ScoreImpact 0
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                       HEALTH CHECK SUMMARY"
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

$FinalSeverity = Get-Severity -Score $GlobalScore

switch ($FinalSeverity) {
    "OK"       { Write-Host "OVERALL STATUS: OK ($GlobalScore/100)" -ForegroundColor Green }
    "Warning"  { Write-Host "OVERALL STATUS: WARNING ($GlobalScore/100)" -ForegroundColor Yellow }
    "Critical" { Write-Host "OVERALL STATUS: CRITICAL ($GlobalScore/100)" -ForegroundColor Red }
}

Write-Host ""

Write-Section "Detailed Results"

foreach ($item in $HealthResults) {
    Write-Status "$($item.Name): $($item.Details)" $item.Status
}

Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                      JSON SUMMARY (for automation)"
Write-Host "==================================================================" -ForegroundColor Cyan

$JsonSummary = [PSCustomObject]@{
    Environment = $Environment
    App         = $App
    Region      = $Region
    Location    = $Location
    MonitoringLocation = $MonitoringLocation
    Score       = $GlobalScore
    Severity    = $FinalSeverity
    Timestamp   = (Get-Date)
    Results     = @($HealthResults)
}

Write-Host ($JsonSummary | ConvertTo-Json -Depth 10)

Write-Host ""
Write-Host "Health check completed." -ForegroundColor Cyan

return $JsonSummary
