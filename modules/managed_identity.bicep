
// Module: Managed Identity - Creates a user-assigned managed identity

//@description('Environment name (dev1, sit, uat, prod)')
//param environment string

@description('Region for resources')
param location string

@description('Tags to apply to the managed identity')
param tags object = {}

//@description('Managed identity name pattern')
//param namePattern string = 'mi-ae-bcrevdata'

@description('Managed identity')
param managedIdentityName string

//var managedIdentityName = '${namePattern}-${environment}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

output managedIdentityName string = managedIdentity.name
output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId


