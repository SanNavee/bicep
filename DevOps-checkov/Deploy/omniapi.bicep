param location string = resourceGroup().location

@minLength(3)
@description('The name of the hosting AppService Plan')
param hostingPlanName string

@minLength(3)
@description('The name of the Omni Core API instance used to formulate the URI')
param omniCoreApiName string

@minLength(5)
@description('ClientId of the resource defined in Azure AD App Registration')
param omniCoreApiClientId string

@description('Identifier Uri for Omni Core API in AD Registration manifest')
param omniCoreApiResourceIdentifier string = ''

@minLength(1)
@description('Uri of the Omni Core AppServer Resource for the HCM to use')
param omniCoreApiHybridConnectionHost string

@description('Port Number of the Omni Core AppServer Resource for the HCM to use')
param omniCoreApiHybridConnectionPort int

@minLength(5)
@description('Name of the Azure KeyVault instance')
param omniCoreAppsKeyVaultName string

@description('Connection String of the Azure Storage Account')
param omniAppsStorageConnectionString string

param relay_namespace_name_var string
param hybrid_connection_name string
param ai_name_var string

//OmniCore Api Appservice
resource omniCoreApiName_resource 'Microsoft.Web/sites@2021-01-15' = {
  name: omniCoreApiName
  location: location
  tags: {
    product: 'Lexis Omni'
  }
  kind: 'api'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', hostingPlanName)
    httpsOnly: true
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    siteConfig: {
      http20Enabled: true
      ftpsState: 'Disabled'
      alwaysOn: true
      use32BitWorkerProcess: false
      virtualApplications: [
        {
          virtualPath: '/'
          physicalPath: 'site\\wwwroot'
          preloadEnabled: true
        }
        {
          virtualPath: '/DocumentProcessingWebJob'
          physicalPath: 'site\\jobs\\continuous\\DocumentProcessingWebJob'
          preloadEnabled: false
        }
      ]
    }
  }
}
//OmniCore Api Appsettings
resource omniCoreApiName_appsettings 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: omniCoreApiName_resource
  name: 'appsettings'
  properties: {
    KeyVaultName: omniCoreAppsKeyVaultName
    APPINSIGHTS_INSTRUMENTATIONKEY: reference(ai_name.id, '2020-02-02').InstrumentationKey
  }
}

//OmniCore Api Appservice Application Insights - Ref the instrumentation key in the appsettings
resource ai_name 'Microsoft.Insights/components@2020-02-02' = {
  name: ai_name_var
  kind: 'api'
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', ai_name_var)}': 'Resource'
    product: 'Lexis Omni'
  }
  properties: {
    Application_Type: 'web'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api Appservice keyvault inclusion with GET and LIST
resource omniCoreAppsKeyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId:omniCoreApiName_resource.identity.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

//OmniCore Api CoreRestApi AzureAd Instance keyvault inclusion
resource omniCoreAppsKeyVaultName_CoreRestApi_AzureAd_Instance 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: any('${omniCoreAppsKeyVaultName}/CoreRestApi--AzureAd--Instance')
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: environment().authentication.loginEndpoint
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api CoreRestApi AzureAd TenantId keyvault inclusion
resource omniCoreAppsKeyVaultName_CoreRestApi_AzureAd_TenantId 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/CoreRestApi--AzureAd--TenantId'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: subscription().tenantId
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api CoreRestApi AzureAd Audiences keyvault inclusion
resource omniCoreAppsKeyVaultName_CoreRestApi_AzureAd_Audiences 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/CoreRestApi--AzureAd--Audiences'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: omniCoreApiResourceIdentifier
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api CoreRestApi AzureAd ClientId keyvault inclusion
resource omniCoreAppsKeyVaultName_CoreRestApi_AzureAd_ClientId 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/CoreRestApi--AzureAd--ClientId'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: omniCoreApiClientId
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api CoreRestApi OmniCoreAppServers keyvault inclusion
resource omniCoreAppsKeyVaultName_CoreRestApi_OmniCoreAppServers 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/CoreRestApi--OmniCoreAppServers'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: 'AppserverDC://${omniCoreApiHybridConnectionHost}:${omniCoreApiHybridConnectionPort}'
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//OmniCore Api ConnectionStrings AzureWebJobsStorage keyvault inclusion
resource omniCoreAppsKeyVaultName_ConnectionStrings_AzureWebJobsStorage 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${omniCoreAppsKeyVaultName}/ConnectionStrings--AzureWebJobsStorage'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: omniAppsStorageConnectionString
    contentType: 'text/plain'
  }
  dependsOn: [
    omniCoreApiName_resource
  ]
}

//Relay is created
resource relay_namespace_name 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: relay_namespace_name_var
  location: location
  tags: {
    product: 'Lexis Omni'
  }
  sku: {
    name: 'Standard'
  }
  properties: {}
}

//Hybrid Connection for Relay
resource relay_namespace_name_hybrid_connection_name 'Microsoft.Relay/Namespaces/HybridConnections@2017-04-01' = {
  parent: relay_namespace_name
  name: hybrid_connection_name
  properties: {
    requiresClientAuthorization: true
    userMetadata: '[{"key":"endpoint","value":"${omniCoreApiHybridConnectionHost}:${omniCoreApiHybridConnectionPort}"}]'
  }
}
//Hybrid Connection Listener for Relay
resource relay_namespace_name_hybrid_connection_name_defaultListener 'Microsoft.Relay/namespaces/hybridConnections/authorizationRules@2017-04-01' = {
  parent: relay_namespace_name_hybrid_connection_name
  name: 'defaultListener'
  properties: {
    rights: [
      'Listen'
    ]
  }
  dependsOn: [
  ]
}

//Hybrid Connection namespace for Relay
resource relay_namespace_name_hybrid_connection_name_defaultSender 'Microsoft.Relay/namespaces/hybridConnections/authorizationRules@2017-04-01' = {
  parent: relay_namespace_name_hybrid_connection_name
  name: 'defaultSender'
  properties: {
    rights: [
      'Send'
    ]
  }
  dependsOn: [
  ]
}

resource omniCoreApiName_relay_namespace_name_hybrid_connection_name 'Microsoft.Web/sites/hybridConnectionNamespaces/relays@2021-01-15' = {
  name: '${omniCoreApiName}/${relay_namespace_name_var}/${hybrid_connection_name}'
  properties: {
    relayArmUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Relay/namespaces/${relay_namespace_name_var}/HybridConnections/${hybrid_connection_name}'
    hostname: omniCoreApiHybridConnectionHost
    port: omniCoreApiHybridConnectionPort
    sendKeyName: 'defaultSender'
    sendKeyValue: ''
  }
  dependsOn: [
    relay_namespace_name
    omniCoreApiName_resource
  ]
}

output OmniCoreApiEndpoint string = 'https://${omniCoreApiName_resource.properties.defaultHostName}/api/'
