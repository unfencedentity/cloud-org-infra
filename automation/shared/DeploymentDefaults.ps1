Set-StrictMode -Version Latest

$script:RegionToLocationMap = @{
    deu = "denmarkeast"
    weu = "westeurope"
    neu = "northeurope"
    eus = "eastus"
    wus = "westus"
}

$script:DefaultDeploymentRegion = "deu"

function Get-DefaultDeploymentRegion {
    return $script:DefaultDeploymentRegion
}

function Get-SupportedDeploymentRegions {
    return @($script:RegionToLocationMap.Keys)
}

function Get-SupportedDeploymentLocations {
    return @($script:RegionToLocationMap.Values)
}

function Get-DeploymentLocationFromRegion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Region
    )

    $normalizedRegion = $Region.Trim().ToLowerInvariant()

    if (-not $script:RegionToLocationMap.ContainsKey($normalizedRegion)) {
        throw "Unsupported region code '$Region'. Supported values: $($script:RegionToLocationMap.Keys -join ', ')."
    }

    return $script:RegionToLocationMap[$normalizedRegion]
}

function Resolve-DeploymentRegionLocation {
    param(
        [string]$Region,
        [string]$Location
    )

    if ([string]::IsNullOrWhiteSpace($Region)) {
        $Region = Get-DefaultDeploymentRegion
    }

    $normalizedRegion = $Region.Trim().ToLowerInvariant()
    $expectedLocation = Get-DeploymentLocationFromRegion -Region $normalizedRegion

    if ([string]::IsNullOrWhiteSpace($Location)) {
        $Location = $expectedLocation
    }

    $normalizedLocation = $Location.Trim().ToLowerInvariant()

    if ($normalizedLocation -ne $expectedLocation) {
        throw "Location '$Location' does not match region '$normalizedRegion'. Expected '$expectedLocation'."
    }

    return [PSCustomObject]@{
        Region   = $normalizedRegion
        Location = $normalizedLocation
    }
}
