param location string = resourceGroup().location
param docAppFuncName string
param docFuncAppInsightsName string
param keyVaultName string
param storageAccountName string
param fileShareName string
param mainStorageKeyvaultParamName string
param functionAppServiceSKU string

var plan_name_var_var = 'plan-${docAppFuncName}'

//Functions
resource docAppFuncName_resource 'Microsoft.Web/sites@2021-01-15' = {
  name: docAppFuncName
  location: location
  tags: {
    product: 'Lexis Omni'
  }
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${docAppFuncName}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${docAppFuncName}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: plan_name_var.id
    reserved: false
    isXenon: false
    hyperV: false
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    redundancyMode: 'None'
    storageAccountRequired: false
    httpsOnly: true
  }
}

//Appservice plan for Functions (Consumptions plan)
resource plan_name_var 'Microsoft.Web/serverfarms@2021-01-15' = if (empty(functionAppServiceSKU)) {
  name: plan_name_var_var
  location: location
  tags: {
    product: 'Lexis Omni'
  }
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

// site configuration
resource docAppFuncName_web 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: docAppFuncName_resource
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    phpVersion: '5.6'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$omni-documents'
    azureStorageAccounts: {}
    scmType: 'None'
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetRouteAllEnabled: false
    vnetPrivatePortsCount: 0
    cors: {
      allowedOrigins: [
        'https://functions.azure.com'
        'https://functions-staging.azure.com'
        'https://functions-next.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    managedServiceIdentityId: 27009
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.0'
    ftpsState: 'Disabled'
  }
}

// Functions configuration referring to Key vault
resource docAppFuncName_appsettings 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: docAppFuncName_resource
  name: 'appsettings'
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~4'
    AzureWebJobsDashboard: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/StorageConnectionString/)'
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/StorageConnectionString/)'
    StorageConnectionString: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${mainStorageKeyvaultParamName}/)'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/StorageConnectionString/)'
    WEBSITE_CONTENTSHARE: docAppFuncName
    APPINSIGHTS_INSTRUMENTATIONKEY: reference(docFuncAppInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
    fileShareName: fileShareName
  }
  dependsOn: [
    keyVaultName_add
  ]
}

resource docAppFuncName_docAppFuncName_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2021-01-15' = {
  parent: docAppFuncName_resource
  name: '${docAppFuncName}.azurewebsites.net'
  properties: {
    siteName: docAppFuncName
    hostNameType: 'Verified'
  }
}

// Document Assembly keyvault inclusion
resource keyVaultName_Resources_DocumentAssembly_AppKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: '${keyVaultName}/Resources--DocumentAssembly--AppKey'
  properties: {
    contentType: 'text/plain'
    value: listKeys(docAppFuncName_DocumentAssembly.id, '2021-02-01').default
  }
}

// HTTP Trigger for Functions
resource docAppFuncName_DocumentAssembly 'Microsoft.Web/sites/functions@2021-01-15' = {
  parent: docAppFuncName_resource
  name: 'DocumentAssembly'
  properties: {
    script_root_path_href: 'https://${docAppFuncName}.azurewebsites.net/admin/vfs/site/wwwroot/DocumentAssembly/'
    script_href: 'https://${docAppFuncName}.azurewebsites.net/admin/vfs/site/wwwroot/bin/LexisNexis.Omni.Everyfile.Functions.DocumentHandling.dll'
    config_href: 'https://${docAppFuncName}.azurewebsites.net/admin/vfs/site/wwwroot/DocumentAssembly/function.json'
    test_data_href: 'https://${docAppFuncName}.azurewebsites.net/admin/vfs/data/Functions/sampledata/DocumentAssembly.dat'
    href: 'https://${docAppFuncName}.azurewebsites.net/admin/functions/DocumentAssembly'
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'admin'
          methods: [
            'put'
            'post'
          ]
        }
        {
          name: 'return'
          type: 'http'
          direction: 'out'
        }
      ]
    }
  }
  dependsOn: [
    keyVaultName_add
    docAppFuncName_appsettings
  ]
}

// Functions Application Insights
resource docFuncAppInsightsName_resource 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: docFuncAppInsightsName
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', docFuncAppInsightsName)}': 'Resource'
    product: 'Lexis Omni'
  }
  kind: ''
  properties: {
    Application_Type: 'web'
  }
}


// Conditional fileshare deployment
resource storageAccountName_default_templates 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = if (empty(fileShareName)) {
  name: '${storageAccountName}/default/templates'
  properties: {
    accessTier: 'Hot'
    shareQuota: 5
    enabledProtocols: 'SMB'
  }
}

//function Appservice keyvault inclusion with GET and LIST
resource keyVaultName_add 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: docAppFuncName_resource.identity.principalId
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

output DocFuncAppEndpoint string = 'https://${docAppFuncName_resource.properties.defaultHostName}'
output docAppFuncName_resourceHostName string = docAppFuncName_resource.properties.defaultHostName
