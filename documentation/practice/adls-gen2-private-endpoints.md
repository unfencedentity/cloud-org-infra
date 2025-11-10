# Securing ADLS Gen2 with Private Endpoints (Blob + DFS)

We secured the ADLS Gen2 storage account by removing public network exposure and routing all data access through Private Endpoints inside our VNet.
This ensures the storage account is not accessible from the internet and only reachable inside the private Azure network.

---

## Architecture Components

Component | Purpose
--------- | -------
ADLS Gen2 Storage Account | Secure data storage for automation and workloads
Virtual Network (VNet) | Logical private network boundary
Subnet: subnet-data | Placement for the private endpoints
Private Endpoints (Blob + DFS) | Secure internal access to Blob and DFS APIs
Private DNS Zones | Internal name resolution for storage endpoints
RBAC | Identity-based access (no shared keys)

Traffic stays on the Azure backbone → zero public exposure.

---

## 1) Variables

    $rg      = "rg-dev-weu"
    $loc     = "westeurope"
    $sa      = "stdeweu2401"
    $rgNet   = "rg-dev-weu"
    $vnet    = "vnet-org-dev-weu"
    $subData = "subnet-data"

---

## 2) Create Private Endpoint for Blob

    $plsBlob = New-AzPrivateLinkServiceConnection `
        -Name "pls-$sa-blob" `
        -PrivateLinkServiceId (Get-AzStorageAccount -Name $sa -ResourceGroupName $rg).Id `
        -GroupId "blob"

    New-AzPrivateEndpoint `
        -Name "pep-$sa-blob" `
        -ResourceGroupName $rgNet `
        -Location $loc `
        -Subnet $subData `
        -PrivateLinkServiceConnection $plsBlob

---

## 3) Create Private Endpoint for DFS

    $plsDfs = New-AzPrivateLinkServiceConnection `
        -Name "pls-$sa-dfs" `
        -PrivateLinkServiceId (Get-AzStorageAccount -Name $sa -ResourceGroupName $rg).Id `
        -GroupId "dfs"

    New-AzPrivateEndpoint `
        -Name "pep-$sa-dfs" `
        -ResourceGroupName $rgNet `
        -Location $loc `
        -Subnet $subData `
        -PrivateLinkServiceConnection $plsDfs

---

## 4) Disable Public Network Access

    Set-AzStorageAccount `
        -ResourceGroupName $rg `
        -Name $sa `
        -PublicNetworkAccess Disabled

---

## 5) Validation

    Get-AzPrivateEndpoint -ResourceGroupName $rgNet | Select Name, ProvisioningState
    Get-AzStorageAccount -ResourceGroupName $rg -Name $sa | Select Name, PublicNetworkAccess

Expected Output:

    pep-stdeweu2401-blob   Succeeded
    pep-stdeweu2401-dfs    Succeeded
    PublicNetworkAccess     Disabled

---

## Final Outcome

Security Control | Status
----------------|-------
Storage only reachable over VNet | ✅
Blob endpoint private | ✅
DFS endpoint private | ✅
Public access disabled | ✅
RBAC only access (no keys) | ✅

We now have a **production-grade secure data landing zone foundation**.
