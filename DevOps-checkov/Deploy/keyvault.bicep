param location string = resourceGroup().location
param azureAdminObjectId string
param externalStorageConnectionString string
param accessPolicies array = [
  {
    tenantId: subscription().tenantId
    objectId: azureAdminObjectId
    permissions: {
      secrets: [
        'Get'
        'List'
        'Set'
        'Delete'
        'Recover'
        'Backup'
        'Restore'
        'purge'
      ]
    }
  }
]

param enabledForDeployment bool = false
param enabledForTemplateDeployment bool = false
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = false
param tenant string = subscription().tenantId

param networkAcls object ={
  defaultAction: 'Allow'
  bypass: 'AzureServices'
}

param StorageConnectionString string = 'StorageConnectionString'
param omniAppsStorageNameid string
param omniAppsStorageNameapiVersion string
param omniAppsKeyVaultName_var string
param omniAppsStorageName_var string

resource omniAppsKeyVaultName 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: omniAppsKeyVaultName_var
  location: location
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableRbacAuthorization: enableRbacAuthorization
    tenantId: tenant
    accessPolicies: accessPolicies
    networkAcls: networkAcls
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource omniAppsKeyVaultName_StorageConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniAppsKeyVaultName.name}/${StorageConnectionString}'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${omniAppsStorageName_var};EndpointSuffix=core.windows.net;AccountKey=${listKeys(omniAppsStorageNameid, omniAppsStorageNameapiVersion).keys[1].value}'
    contentType: 'text/plain'
  }
}

resource omniAppsKeyVaultName_var_ExternalStorageConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: omniAppsKeyVaultName
  name: 'ExternalStorageConnectionString'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: !empty(externalStorageConnectionString) ? externalStorageConnectionString : 'DefaultEndpointsProtocol=https;AccountName=${omniAppsStorageName_var};EndpointSuffix=core.windows.net;AccountKey=${listKeys(omniAppsStorageNameid, omniAppsStorageNameapiVersion).keys[0].value}'
    contentType: 'text/plain'
  }
}

output omniAppsKeyVaultName string = omniAppsKeyVaultName.name
output omnikeyvaultnameid string = omniAppsKeyVaultName.id
