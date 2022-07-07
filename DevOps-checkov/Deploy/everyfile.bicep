@minLength(3)
@description('The name of the hosting AppService Plan')
param hostingPlanName string

param location string = resourceGroup().location

@minLength(3)
@description('The name of the EveryFile instance used to formulate the URI')
param everyFileName string

@minLength(3)
@description('The Domain name where the apps are registered')
param omniAppsDomainName string

@description('EveryFile Client Id')
param everyFileClientId string = ''

@description('EveryFile Client Secret')
param everyFileClientSecret string = ''

@minLength(3)
@description('Identifier of the Omni Core API resource defined in it\'s Azure AD App Registration')
param omniCoreApiResourceIdentifier string

@description('The Url of the Omni Core Api')
param omniCoreApiEndpoint string

@minLength(5)
@description('Name of the Azure KeyVault instance')
param omniAppsKeyVaultName string

@description('MS Graph API version')
param msGraphVersion string

@description('Whether to include the PowerBI configuration for EveryFile')
param configurePowerBI bool

@description('Whether to include the iManage configuration in Everyfile')
param configureIManage bool

@description('Endpoint of the iManage resource')
param iManageEndpoint string

@description('Visualfiles identified Client Code used for mapping the iManage workspace')
param iManageClientCodeField string

@description('Visualfiles identified Matter Code used for mapping the iManage workspace')
param iManageMatterCodeField string

@description('Client Id issued by iManage when Everyfile was registered')
param iManageEveryfileClientId string

@description('Client Secret issued by iManage when Everyfile was registered')
param iManageEveryfileClientSecret string

@description('Document Function App Endpoint')
param docFuncAppEndpoint string

var ai_name_var = 'appi-${everyFileName}'
var baseProps = {
  'Resources:OmniCoreApi:Resource': omniCoreApiResourceIdentifier
  'Resources:OmniCoreApi:Endpoint': omniCoreApiEndpoint
  'Resources:MSGraph:Resource': 'https://graph.microsoft.com'
  'Resources:MSGraph:Endpoint': 'https://graph.microsoft.com/${msGraphVersion}'
  KeyVaultName: omniAppsKeyVaultName
  'Customisations:RecentItemsMaximumLimit': 20
  'Customisations:CompanyName': 'Everyfile'
}
var everyFilePowerBIProps = {
  'Resources:PowerBI:Resource': 'https://analysis.windows.net/powerbi/api'
  'Resources:PowerBI:Endpoint': 'https://api.powerbi.com/'
}
var everyFileiManageProps = {
  'Resources:iManage:Endpoint': iManageEndpoint
  'Resources:iManage:ClientCodeField': iManageClientCodeField
  'Resources:iManage:MatterCodeField': iManageMatterCodeField
  'Resources:iManage:Scopes': 'user'
  'Resources:iManage:AuthorisationEndpoint': '${iManageEndpoint}/auth/oauth2/authorize'
  'Resources:iManage:TokenEndpoint': '${iManageEndpoint}/auth/oauth2/token'
  'Resources:DocumentAssembly:Endpoint': configureIManage ? docFuncAppEndpoint : 'empty'
}
var appsettings = union(baseProps, (configurePowerBI ? everyFilePowerBIProps : json('{}')), (configureIManage ? everyFileiManageProps : json('{}')))

resource everyFileName_resource 'Microsoft.Web/sites@2021-01-15' = {
  name: everyFileName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    product: 'Lexis Omni'
  }
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
    }
  }
}

resource everyFileName_appsettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: everyFileName_resource
  name: 'appsettings'
  properties: union(appsettings, json('{"APPINSIGHTS_INSTRUMENTATIONKEY":"${reference(ai_name.id, ai_name.apiVersion).InstrumentationKey}"}'))
}

resource ai_name 'Microsoft.Insights/components@2020-02-02' = {
  name: ai_name_var
  kind: 'webapp'
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', ai_name_var)}': 'Resource'
    product: 'Lexis Omni'
  }
  properties: {
    Application_Type: everyFileName
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppskeyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${omniAppsKeyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: everyFileName_resource.identity.principalId
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

resource omniAppskeyVaultName_EveryFile_AzureAd_ClientId 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${omniAppsKeyVaultName}/EveryFile--AzureAd--ClientId'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: everyFileClientId
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppskeyVaultName_EveryFile_AzureAd_ClientSecret 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${omniAppsKeyVaultName}/EveryFile--AzureAd--ClientSecret'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: everyFileClientSecret
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppskeyVaultName_EveryFile_AzureAd_Instance 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${omniAppsKeyVaultName}/EveryFile--AzureAd--Instance'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: environment().authentication.loginEndpoint
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppskeyVaultName_EveryFile_AzureAd_TenantId 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${omniAppsKeyVaultName}/EveryFile--AzureAd--TenantId'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: subscription().tenantId
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppsKeyVaultName_EveryFile_AzureAd_Domain 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${omniAppsKeyVaultName}/EveryFile--AzureAd--Domain'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: omniAppsDomainName
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppsKeyVaultName_Resources_iManage_ClientId 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = if (configureIManage == true) {
  name: '${omniAppsKeyVaultName}/Resources--iManage--ClientId'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: iManageEveryfileClientId
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}

resource omniAppsKeyVaultName_Resources_iManage_ClientSecret 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = if (configureIManage == true) {
  name: '${omniAppsKeyVaultName}/Resources--iManage--ClientSecret'
  tags: {
    product: 'Lexis Omni'
  }
  properties: {
    value: iManageEveryfileClientSecret
    contentType: 'text/plain'
  }
  dependsOn: [
    everyFileName_resource
  ]
}


output EveryFileEndpoint string = 'https://${everyFileName_resource.properties.defaultHostName}'
