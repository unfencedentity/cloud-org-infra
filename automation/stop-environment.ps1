[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [string]$App,

    [Parameter(Mandatory = $true)]
    [string]$Region
)

$ErrorActionPreference = "Stop"

$resourceGroupName = "rg-$App-$Environment-$Region"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Stopping Azure environment runtime resources" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Environment : $Environment"
Write-Host "Application : $App"
Write-Host "Region      : $Region"
Write-Host "Resource RG : $resourceGroupName"
Write-Host ""

$summary = @()

$resourceGroup = Get-AzResourceGroup `
    -Name $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $resourceGroup) {
    throw "Resource group not found: $resourceGroupName"
}

Write-Host "Discovering virtual machines..."

$vms = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Status `
    -ErrorAction SilentlyContinue

if (-not $vms -or $vms.Count -eq 0) {
    Write-Host "No virtual machines found."
}
else {
    foreach ($vm in $vms) {
        $powerState = ($vm.Statuses | Where-Object {
            $_.Code -like "PowerState/*"
        }).DisplayStatus

        Write-Host "VM found: $($vm.Name) | State: $powerState"

        if ($powerState -eq "VM deallocated" -or $powerState -eq "VM stopped") {
            Write-Host "VM already stopped/deallocated: $($vm.Name)" -ForegroundColor Yellow

            $summary += [PSCustomObject]@{
                ResourceType = "VirtualMachine"
                Name         = $vm.Name
                Action       = "Skipped"
                State        = $powerState
            }

            continue
        }

        if ($PSCmdlet.ShouldProcess($vm.Name, "Stop and deallocate VM")) {
            Write-Host "Stopping and deallocating VM: $($vm.Name)" -ForegroundColor Yellow

            Stop-AzVM `
                -ResourceGroupName $resourceGroupName `
                -Name $vm.Name `
                -Force | Out-Null

            $summary += [PSCustomObject]@{
                ResourceType = "VirtualMachine"
                Name         = $vm.Name
                Action       = "Stopped"
                State        = "Deallocated requested"
            }
        }
    }
}

Write-Host ""
Write-Host "Discovering App Services..."

$appServices = Get-AzWebApp `
    -ResourceGroupName $resourceGroupName `
    -ErrorAction SilentlyContinue

if (-not $appServices -or $appServices.Count -eq 0) {
    Write-Host "No App Services found."
}
else {
    foreach ($appService in $appServices) {
        Write-Host "App Service found: $($appService.Name) | State: $($appService.State)"

        if ($appService.State -eq "Stopped") {
            Write-Host "App Service already stopped: $($appService.Name)" -ForegroundColor Yellow

            $summary += [PSCustomObject]@{
                ResourceType = "AppService"
                Name         = $appService.Name
                Action       = "Skipped"
                State        = "Stopped"
            }

            continue
        }

        if ($PSCmdlet.ShouldProcess($appService.Name, "Stop App Service")) {
            Write-Host "Stopping App Service: $($appService.Name)" -ForegroundColor Yellow

            Stop-AzWebApp `
                -ResourceGroupName $resourceGroupName `
                -Name $appService.Name | Out-Null

            $summary += [PSCustomObject]@{
                ResourceType = "AppService"
                Name         = $appService.Name
                Action       = "Stopped"
                State        = "Stopped requested"
            }
        }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Stop environment summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

if ($summary.Count -gt 0) {
    $summary | Format-Table -AutoSize
}
else {
    Write-Host "No runtime resources were changed."
}

Write-Host ""
Write-Host "Environment stop operation completed." -ForegroundColor Cyan

return $summary
