# AzurePolicy.psm1
# Reusable Azure Policy governance functions

Set-StrictMode -Version Latest

function Ensure-PolicyAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AssignmentName,
        [Parameter(Mandatory)][string]$PolicyDefinitionName,
        [Parameter(Mandatory)][string]$Scope,
        [Parameter()][hashtable]$PolicyParameters
    )

    try {
        Write-Host "Checking policy assignment '$AssignmentName'..."

        $existingAssignment = Get-AzPolicyAssignment `
            -Name $AssignmentName `
            -Scope $Scope `
            -ErrorAction SilentlyContinue

        if ($existingAssignment) {
            Write-Host "Policy assignment already exists. Skipping creation."
            return $existingAssignment
        }

        Write-Host "Retrieving policy definition '$PolicyDefinitionName'..."

        $policyDefinition = Get-AzPolicyDefinition `
            | Where-Object { $_.Properties.DisplayName -eq $PolicyDefinitionName } `
            | Select-Object -First 1

        if (-not $policyDefinition) {
            throw "Policy definition not found: $PolicyDefinitionName"
        }

        Write-Host "Creating policy assignment '$AssignmentName'..."

        $assignment = New-AzPolicyAssignment `
            -Name $AssignmentName `
            -DisplayName $AssignmentName `
            -PolicyDefinition $policyDefinition `
            -Scope $Scope `
            -PolicyParameterObject $PolicyParameters

        Write-Host "Policy assignment created successfully."

        return $assignment
    }
    catch {
        throw "[AzurePolicy] Failed to ensure policy assignment '$AssignmentName' :: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function Ensure-PolicyAssignment
