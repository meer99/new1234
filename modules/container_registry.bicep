// ============================================================================
// Module: Container Registry (ACR)
// Creates an Azure Container Registry with private endpoint support.
// Note: Private endpoints require Premium SKU.
// ============================================================================

@description('Specifies the environment name (e.g., dev, sit, uat, prod)')
param env string

@description('Specifies the location for resources')
param location string

@description('Specifies tags to apply to the container registry')
param tags object = {}

@description('Specifies the name for ACR')
param acrName string

@description('Specifies the SKU for ACR (Premium required for private endpoints)')
param acrSku string

@description('Managed identity resource ID')
param managedIdentityId string

@description('Enable admin user')
param adminUserEnabled bool = false

// Load environment-specific parameters from JSON config
var params = loadJsonContent('../variables/parameters.json')[env]

// --- Existing Network Resources (for Private Endpoint) ---

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: params.vnetname
  scope: resourceGroup(params.vnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  parent: vnet
  name: params.peSubnetName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.azurecr.io'
  scope: resourceGroup(params.dnsZoneSubscription, params.dnsZoneResourceGroup)
}

// --- Container Registry ---

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
  }
}

// --- Private Endpoint for ACR ---

resource privateEndPoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: params.acrPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: params.acrPrivateEndpointName
        properties: {
          privateLinkServiceId: containerRegistry.id
          groupIds: [
            'containerRegistry'
          ]
        }
      }
    ]
  }

  // Private DNS Zone Group
  resource dns_group 'privateDnsZoneGroups@2020-11-01' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: acrName
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}

// --- Outputs ---

@description('The name of the container registry')
output containerRegistryName string = containerRegistry.name

@description('The resource ID of the container registry')
output containerRegistryId string = containerRegistry.id

@description('The login server of the container registry')
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
