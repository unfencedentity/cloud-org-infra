Set-StrictMode -Version Latest

function Test-ObjectProperty {
    param(
        [Parameter(Mandatory = $false)]$Object,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )

    if ($null -eq $Object) {
        return $false
    }

    return @($Object.PSObject.Properties.Name) -contains $PropertyName
}

function Get-ObjectPropertyValue {
    param(
        [Parameter(Mandatory = $false)]$Object,
        [Parameter(Mandatory = $true)][string]$PropertyName,
        $DefaultValue = $null
    )

    if (-not (Test-ObjectProperty -Object $Object -PropertyName $PropertyName)) {
        return $DefaultValue
    }

    return $Object.$PropertyName
}

function Get-FirstCollectionItem {
    param(
        [Parameter(Mandatory = $false)]$Collection
    )

    if ($null -eq $Collection) {
        return $null
    }

    $items = @($Collection)
    if ($items.Count -eq 0) {
        return $null
    }

    return $items[0]
}
