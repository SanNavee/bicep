param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
param omniAppsStorageType string = 'Standard_LRS'
param omniAppsStorageName_var string
param everyFileAppName string


resource omniAppsStorageName 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: omniAppsStorageName_var
  location: location
  sku: {
    name: omniAppsStorageType
  }
  tags: {
    product: 'Lexis Omni'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource storageblob_default 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  name: '${omniAppsStorageName_var}/default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://${everyFileAppName}.azurewebsites.net'
          ]
          allowedMethods: [
            'PUT'
            'OPTIONS'
          ]
          maxAgeInSeconds: 0
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
  dependsOn: [
    omniAppsStorageName
  ]
}
// Determine our connection strings
var omniAppsStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${omniAppsStorageName.name};AccountKey=${listKeys(omniAppsStorageName.id, omniAppsStorageName.apiVersion).keys[0].value}'

// Output the variables
output StorageNameid string = omniAppsStorageName.id
output StorageNameapiVersion string = omniAppsStorageName.apiVersion
output StorageName string = omniAppsStorageName.name

// Output to ref in KV
output omniAppsStorageConnectionString string = omniAppsStorageConnectionString
