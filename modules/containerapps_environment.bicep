// ============================================================================
// Module: Container Apps Environment
// Creates a Container Apps Environment with Log Analytics integration.
// ============================================================================

@description('Specifies the location for resources')
param location string

@description('Specifies tags to apply to resources')
param tags object = {}

@description('Specifies Container Apps Environment name')
param caeName string

@description('Managed identity resource ID')
param managedIdentityId string

@description('Log Analytics workspace customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics workspace shared key')
@secure()
param logAnalyticsSharedKey string

// --- Container Apps Environment ---

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: caeName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: false
  }
}

// --- Outputs ---

@description('The name of the container apps environment')
output containerAppsEnvironmentName string = containerAppsEnvironment.name

@description('The resource ID of the container apps environment')
output containerAppsEnvironmentId string = containerAppsEnvironment.id

@description('The default domain of the container apps environment')
output containerAppsEnvironmentDefaultDomain string = containerAppsEnvironment.properties.defaultDomain

@description('The static IP address of the container apps environment')
output containerAppsEnvironmentStaticIp string = containerAppsEnvironment.properties.staticIp
