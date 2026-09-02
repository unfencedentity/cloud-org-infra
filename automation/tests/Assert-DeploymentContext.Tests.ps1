Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "..\shared\Assert-DeploymentContext.ps1")

Describe "Assert-DeploymentContext" {
    BeforeEach {
        $script:testSubscriptionId = "11111111-1111-1111-1111-111111111111"
        $script:testTenantId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

        $script:testContext = [pscustomobject]@{
            Account = [pscustomobject]@{
                Id = "test-account"
            }
            Subscription = [pscustomobject]@{
                Id = $script:testSubscriptionId
            }
            Tenant = [pscustomobject]@{
                Id = $script:testTenantId
            }
        }

        Mock Get-AzContext {
            return $script:testContext
        }
    }

    It "Accepts a context matching the requested tenant and subscription" {
        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Not Throw

        Assert-MockCalled Get-AzContext -Times 1 -Exactly -Scope It
    }

    It "Rejects a missing context" {
        $script:testContext = $null

        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Throw "No Azure context available."
    }

    It "Rejects an incomplete context" {
        $script:testContext.Account = $null

        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Throw "Azure context is incomplete."
    }

    It "Rejects a different tenant" {
        $script:testContext.Tenant.Id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Throw "Azure tenant mismatch."
    }

    It "Rejects a different subscription" {
        $script:testContext.Subscription.Id = "22222222-2222-2222-2222-222222222222"

        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Throw "Azure subscription mismatch."
    }

    It "Propagates a context lookup failure" {
        Mock Get-AzContext {
            throw "Simulated context lookup failure."
        }

        {
            Assert-DeploymentContext `
                -SubscriptionId $script:testSubscriptionId `
                -TenantId $script:testTenantId
        } | Should Throw "Simulated context lookup failure."
    }
}