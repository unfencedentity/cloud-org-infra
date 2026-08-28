Set-StrictMode -Version Latest

$namingScript = Join-Path $PSScriptRoot "..\shared\DeploymentNaming.ps1"

. $namingScript

Describe "DeploymentNaming.ps1" {
    It "Hashes the provided value instead of the PowerShell automatic input variable" {
        $result = Get-DeterministicHash `
            -Value "test" `
            -Length 6

        $result | Should Be "9f86d0"
    }

    It "Returns the same hash for the same value" {
        $firstResult = Get-DeterministicHash `
            -Value "cloud-org-infra" `
            -Length 10

        $secondResult = Get-DeterministicHash `
            -Value "cloud-org-infra" `
            -Length 10

        $firstResult | Should Be $secondResult
    }

    It "Returns different hashes for different values" {
        $firstResult = Get-DeterministicHash `
            -Value "subscription-one" `
            -Length 6

        $secondResult = Get-DeterministicHash `
            -Value "subscription-two" `
            -Length 6

        $firstResult | Should Not Be $secondResult
    }

    It "Generates the expected globally unique names for fixed test identifiers" {
    $names = Get-DeploymentNames `
        -Environment "dev" `
        -App "core" `
        -Region "deu" `
        -SubscriptionId "11111111-1111-1111-1111-111111111111" `
        -TenantId "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

    $names.StorageAccountName | Should Be "stcoredevdeuf0f68f"
    $names.KeyVaultName | Should Be "kvcoredevdeuf0f68f"
    $names.WebAppName | Should Be "appcoredevdeub3b82dbdf9"
}

    It "Generates different global names for different subscriptions" {
        $firstNames = Get-DeploymentNames `
            -Environment "dev" `
            -App "core" `
            -Region "deu" `
            -SubscriptionId "11111111-1111-1111-1111-111111111111" `
            -TenantId "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

        $secondNames = Get-DeploymentNames `
            -Environment "dev" `
            -App "core" `
            -Region "deu" `
            -SubscriptionId "22222222-2222-2222-2222-222222222222" `
            -TenantId "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

        $firstNames.StorageAccountName |
            Should Not Be $secondNames.StorageAccountName

        $firstNames.KeyVaultName |
            Should Not Be $secondNames.KeyVaultName

        $firstNames.WebAppName |
            Should Not Be $secondNames.WebAppName
    }
}