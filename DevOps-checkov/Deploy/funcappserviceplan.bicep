// @minLength(1)
// param environmentName string

// @minLength(1)
// param locationAbbreviation string

// @minLength(3)
// param instance string

param docAppFuncName string

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
  ''
])
@description('Describes plan\'s pricing tier and capacity')
param functionAppServiceSKU string

@minValue(1)
@description('Describes plan\'s instant count')
param skuCapacity int = 1

var plan_name_var_var = 'plan-${docAppFuncName}'

//Appservice plan for Docfunc
resource plan_name_var 'Microsoft.Web/serverfarms@2021-01-15' =if (functionAppServiceSKU == 'B1'){
  name: plan_name_var_var
  location: location
  sku: {
    name: functionAppServiceSKU
    capacity: skuCapacity
  }
  tags: {
    product: 'Lexis Omni'
  }
}

output plan_name_varForOmni string = plan_name_var.name

