@minLength(1)
param environmentName string

@minLength(1)
param locationAbbreviation string

@minLength(3)
param instance string

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('Describes plan\'s pricing tier and capacity')
param appServicePlanSKUName string

param functionAppServiceSKU string

@description('Whether to include the iManage configuration in Everyfile')
param configureIManage bool

@description('Whether to include the PowerBI configuration in EveryFile')
param configurePowerBI bool

@description('EveryFile Client Id')
param everyFileClientId string

@description('EveryFile Client Secret')
param everyFileClientSecret string

@description('Visualfiles identified Client Code used for mapping the iManage workspace')
param iManageClientCodeField string

@description('Endpoint of the iManage resource')
param iManageEndpoint string

@description('Client Id issued by iManage when Everyfile was registered')
param iManageEveryfileClientId string

@description('Client Secret issued by iManage when Everyfile was registered')
param iManageEveryfileClientSecret string

@description('Visualfiles identified Matter Code used for mapping the iManage workspace')
param iManageMatterCodeField string

@description('MS Graph API version')
param msGraphVersion string = 'v1.0'
@minLength(3)
@description('The Domain name where the apps are registered')
param omniAppsDomainName string

param externalStorageConnectionString string
param fileShareName string
param azureAdminObjectId string
param location string = resourceGroup().location
param omniCoreApiClientId string
param omniCoreApiHybridConnectionHost string
param omniCoreApiHybridConnectionPort int
param omniCoreApiResourceIdentifier string

var relay_namespace_name_var = 'relayapi${environmentName}${locationAbbreviation}${instance}'
var hybrid_connection_name = 'hycnapi${environmentName}${locationAbbreviation}${instance}'
var ai_name_var = 'appi-core-api-${environmentName}-${locationAbbreviation}-${instance}'
var omniCoreApiName = 'api-core-${environmentName}-${locationAbbreviation}-${instance}'
var omniAppsStorageConnectionString = storagedeployment.outputs.omniAppsStorageConnectionString
var everyFileAppName = 'app-ef-${environmentName}-${locationAbbreviation}-${instance}'
var omniAppsStorageName_var = 'stefdata${environmentName}${locationAbbreviation}${instance}'
var omniAppsKeyVaultName_var = 'kv-ef-${environmentName}-${locationAbbreviation}-${instance}'
var docFuncAppName = 'func-ef-doc-${environmentName}-${locationAbbreviation}-${instance}'
var docFuncAppInsightsName = 'appi-func-ef-doc-${environmentName}-${locationAbbreviation}-${instance}'
var docFuncAppEndpoint = configureIManage ? functionsdoc.outputs.DocFuncAppEndpoint : 'empty'
var mainStorageKeyvaultParamName = empty(externalStorageConnectionString) ? 'StorageConnectionString' : 'ExternalStorageConnectionString'

//Storage Account
module storagedeployment 'storage.bicep' ={
  name: 'omniAppsStorageName'
  params:{
    everyFileAppName:everyFileAppName
    omniAppsStorageName_var:omniAppsStorageName_var
    location:location
  }
}

//Keyavult
module keyvaultDeployment 'keyvault.bicep' ={
  name: 'keyvaultDeployment'
  params: {
    omniAppsStorageNameid: storagedeployment.outputs.StorageNameid
    omniAppsStorageNameapiVersion: storagedeployment.outputs.StorageNameapiVersion
    azureAdminObjectId: azureAdminObjectId
    omniAppsKeyVaultName_var: omniAppsKeyVaultName_var
    omniAppsStorageName_var: omniAppsStorageName_var
    externalStorageConnectionString: externalStorageConnectionString
    location:location
  }
}

//Appservice plan for Everyfile
module appServicePlanDeployment 'appserviceplan.bicep' ={
name: 'appServicePlanDeployment'
params: {
    environmentName: environmentName
    instance: instance
    locationAbbreviation: locationAbbreviation
    appServicePlanSKUName: appServicePlanSKUName
    location:location
  }
  dependsOn:[
    storagedeployment
  ]
}

//Function appservice plan for Docfunc
module functionAppPlanDeployment 'funcappserviceplan.bicep' ={
  name: 'functionAppPlanDeployment'
  params: {
      docAppFuncName: docFuncAppName
      functionAppServiceSKU: functionAppServiceSKU
      location:location
    }
    dependsOn:[
      keyvaultDeployment
      storagedeployment
    ]
  }

//Function with Consumption Plan
module functionsdoc 'docfunc.bicep' = if (configureIManage) {
name: 'DocfuncDeployment'
params: {
    docAppFuncName: docFuncAppName
    docFuncAppInsightsName: docFuncAppInsightsName
    keyVaultName: omniAppsKeyVaultName_var
    location: location
    storageAccountName: omniAppsStorageName_var
    fileShareName: fileShareName
    mainStorageKeyvaultParamName: mainStorageKeyvaultParamName
    functionAppServiceSKU: functionAppServiceSKU
  }
  dependsOn:[
    omniCoreApiDeployment
    keyvaultDeployment
    storagedeployment
  ]
}

//Omnicore Api
module omniCoreApiDeployment 'omniapi.bicep' ={
  name: 'omniCoreApiDeployment'
  params: {
    ai_name_var:ai_name_var
    hostingPlanName:appServicePlanDeployment.outputs.hostingPlanNameforomni
    hybrid_connection_name:hybrid_connection_name
    omniCoreApiName:omniCoreApiName
    omniCoreApiClientId:omniCoreApiClientId
    omniAppsStorageConnectionString: omniAppsStorageConnectionString
    omniCoreApiHybridConnectionHost:omniCoreApiHybridConnectionHost
    omniCoreApiHybridConnectionPort:omniCoreApiHybridConnectionPort
    omniCoreApiResourceIdentifier:omniCoreApiResourceIdentifier
    omniCoreAppsKeyVaultName: omniAppsKeyVaultName_var
    relay_namespace_name_var: relay_namespace_name_var
    location:location
  }
  dependsOn:[
    keyvaultDeployment
  ]
}

//Everyfile Appservice
module everyfileDeployment 'everyfile.bicep' ={
  name:'everyfileDeployment'
  params:{
    configureIManage:configureIManage
    configurePowerBI:configurePowerBI
    docFuncAppEndpoint:docFuncAppEndpoint
    everyFileClientId:everyFileClientId
    everyFileClientSecret:everyFileClientSecret
    iManageClientCodeField:iManageClientCodeField
    iManageEndpoint:iManageEndpoint
    iManageEveryfileClientId:iManageEveryfileClientId
    iManageEveryfileClientSecret:iManageEveryfileClientSecret
    iManageMatterCodeField:iManageMatterCodeField
    msGraphVersion:msGraphVersion
    everyFileName: everyFileAppName
    hostingPlanName:appServicePlanDeployment.outputs.hostingPlanNameforomni
    omniCoreApiResourceIdentifier:omniCoreApiResourceIdentifier
    omniAppsDomainName:omniAppsDomainName
    omniCoreApiEndpoint:reference('OmniCoreApiDeployment', '2017-05-10').outputs.OmniCoreApiEndpoint.value
    omniAppsKeyVaultName:omniAppsKeyVaultName_var
    location:location
  }
}

//Optional Storage sync service
module sssDeployment 'stgpart1.bicep' = if (empty(externalStorageConnectionString)) {
  name: 'sssDeployment'
  params:{
    environmentName:environmentName
    instance:instance
    locationAbbreviation:locationAbbreviation
    location:location
  }
  dependsOn:[
    storagedeployment
  ]
}
