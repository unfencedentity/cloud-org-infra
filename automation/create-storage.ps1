param (
    [string]$ResourceGroupName = "core-dev-rg",
    [string]$StorageAccountName = "coredevlake$(Get-Random -Maximum 9999)",
    [string]$Location = "westeurope",
    [string]$FileSystemName = "raw"
)

Write-Output "Creating Storage Account (Data Lake Gen2)..."

New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName Standard_LRS `
    -Kind StorageV2 `
    -EnableHierarchicalNamespace $true

Write-Output "Creating Data Lake filesystem..."
$ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context
New-AzDataLakeGen2Item -Context $ctx -FileSystem $FileSystemName -Path "/" -Directory
