@minLength(1)
param environmentName string

@minLength(1)
param locationAbbreviation string

@minLength(3)
param instance string

param location string = resourceGroup().location

var storageSyncServices = 'sss-ef-${environmentName}-${locationAbbreviation}-${instance}'
var sssgroupvar = 'sss-group'

//Storage sync service resource
resource storageSyncServices_resource 'microsoft.storagesync/storageSyncServices@2020-09-01' = {
  name: storageSyncServices
  location: location
  properties: {
    incomingTrafficPolicy: 'AllowAllTraffic'
  }
}

//Storage sync service group
resource storageSyncServices_syncgroup 'Microsoft.StorageSync/storageSyncServices/syncGroups@2020-09-01' = {
  parent: storageSyncServices_resource
  name: sssgroupvar
  properties: {}
}




