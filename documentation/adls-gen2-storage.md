# ADLS Gen2 Storage Quickstart (PowerShell)

## 1) Login
```powershell
Connect-AzAccount -DeviceCode
Set-AzContext -Subscription (Get-AzSubscription | Where-Object {$_.State -eq "Enabled"} | Select-Object -First 1 -ExpandProperty Id)

2) RG + Storage
$rg   = "rg-dev-weu"
$sa   = "stdevweu" + (Get-Random -Minimum 1000 -Maximum 9999)
$tags = @{ owner="lucian"; env="dev"; app="core" }

New-CoreResourceGroup -Name $rg -Location "westeurope" -Tags $tags
New-CoreStorageAccount -Name $sa -ResourceGroupName $rg -Tags $tags -EnableHierarchicalNamespace

3) RBAC
$user = (Get-AzADUser -SignedIn)
$saObj = Get-AzStorageAccount -ResourceGroupName $rg -Name $sa
New-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName "Storage Blob Data Contributor" -Scope $saObj.Id -ErrorAction SilentlyContinue

4) Context + Folder + Upload
Set-CoreStorageContext -Name $sa -ResourceGroupName $rg
$ctx = $script:CoreStorageContext

New-AzStorageContainer -Name "raw" -Context $ctx -ErrorAction SilentlyContinue | Out-Null
New-AzDataLakeGen2Item -Context $ctx -FileSystem "raw" -Path "sandbox" -Directory | Out-Null
Set-AzStorageBlobContent -Context $ctx -Container "raw" -File "$env:WINDIR\System32\drivers\etc\hosts" -Blob "sandbox/_keep"
