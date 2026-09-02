function Assert-DeploymentContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId
    )

    $context = Get-AzContext -ErrorAction "Stop"

    if (-not $context) {
        throw "No Azure context available. Authenticate before deployment using GitHub Actions OIDC or Connect-AzAccount."
    }

    if (-not $context.Account -or
        -not $context.Subscription -or
        -not $context.Tenant) {
        throw "Azure context is incomplete. Authenticate again before deployment."
    }

    if ($context.Tenant.Id -ne $TenantId.Trim()) {
        throw "Azure tenant mismatch. Select the intended tenant before deployment."
    }

    if ($context.Subscription.Id -ne $SubscriptionId.Trim()) {
        throw "Azure subscription mismatch. Select the intended subscription before deployment."
    }

    Write-Verbose "Azure context matches the requested tenant and subscription."
}