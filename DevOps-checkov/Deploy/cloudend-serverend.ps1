Connect-AzAccount
$resourceGroup = Read-Host "`n Enter Azure Resource Group name"
$storageAccountName = Read-Host "`n Enter Azure storage account name"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
$agentPath = 'C:\Program Files\Azure\StorageSyncAgent'
$region = Read-Host "`n Enter Azure region name"
$storageSyncName = Read-Host "`n Enter Storage sync name"
$syncGroupName = Read-Host "`n Enter Storage sync Group name"
$registeredServer = Register-AzStorageSyncServer -ResourceGroupName "$resourceGroup" -StorageSyncServiceName "$storageSyncName"
$StorageAccountShareName = Read-Host "`n Enter Azure File Share Name"
$parameters = @{
     StorageSyncServiceName = $storageSyncName
     SyncGroupName = $syncGroupName
     StorageAccountResourceId = $storageAccount.Id
     StorageAccountShareName = $StorageAccountShareName
     ResourceGroupName = $resourceGroup
 }
 New-AzStorageSyncCloudEndpoint @parameters

$ServerEndpointPath = Read-Host "`n Enter the desired path on your registered server which is not on the system volume i.e. D:\Data"
# Get all registered server endpoints
$RegisteredServer = Get-AzStorageSyncServer -ResourceGroupName $resourceGroup `
    -StorageSyncServiceName $storageSyncName
# Create server endpoint
New-AzStorageSyncServerEndpoint `
    -Name $RegisteredServer[0].FriendlyName `
    -ResourceGroupName "$resourceGroup" `
    -StorageSyncServiceName $storageSyncName `
    -SyncGroupName $syncGroupName `
    -ServerResourceId $registeredServer[0].ResourceId  `
    -ServerLocalPath $serverEndpointPath `
    -VolumeFreeSpacePercent $volumeFreeSpacePercentage