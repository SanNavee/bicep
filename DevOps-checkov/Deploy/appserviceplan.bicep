@minLength(1)
param environmentName string

@minLength(1)
param locationAbbreviation string

@minLength(3)
param instance string

param location string = resourceGroup().location

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

@minValue(1)
@description('Describes plan\'s instant count')
param skuCapacity int = 1

var hostingPlanName_var = 'plan-ef-${environmentName}-${locationAbbreviation}-${instance}'

//Appservice plan for Everyfile and Omnicore API
resource hostingPlanName 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: appServicePlanSKUName
    capacity: skuCapacity
  }
  tags: {
    product: 'Lexis Omni'
  }
}

output hostingPlanNameforomni string = hostingPlanName.name
