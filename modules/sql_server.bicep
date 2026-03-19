
/**
    This Bicep file deploys a new SQL Server.
    - The script defines params:
        - location
        - sqlServerName
        - tagDetails
    - SQL Server resource is of type 'Microsoft.Sql/servers@2022-08-01-preview'.
    - Private End Point resource is of type 'Microsoft.Network/privateEndpoints@2021-05-01'
**/

@description('Specifies the location for resource')
param location string

@description('Specifies the tag values for Environment')
param env string

@description('Specifies the name of SQL Server')
param sqlServerName string

@description('Specifies the tags for resources')
param tags object

@description('Specifies the admin username of sql server')
@secure()
param administratorLogin string

@description('Specifies the admin passowrd of sql server')
@secure()
param administratorLoginPassword string

@description('Specifies the name of virtual network name')
param virtualNetworkName string

@description('Specifies the name of vnet Resource Group.')
param vnetResourceGroup string

@description('Specifies the name of private endpoint subnet name')
param subnetName string

@description('Specifies the name of private end point for sql server')
param sqlServerPrivateEndPoint string

@description('Specifies the name of private end point nic name')
param  privateDnsZoneSQLName string

@description('Specifies the tags for resources')
param commonParams object = loadJsonContent('../variables/parameters.json')[env]

//Get vnet details and id
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(vnetResourceGroup)
}

//Get private end point details
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  parent: vnet
  name: subnetName
}


resource privateDnsZonesql 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneSQLName
  scope: resourceGroup(commonParams.dnsZoneSubscription,commonParams.dnsZoneResourceGroup)
}


resource sqlServer 'Microsoft.Sql/servers@2022-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

//Create private end point and associate with sql server
resource privateEndPoint 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: sqlServerPrivateEndPoint
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnet.id
    }
    //customNetworkInterfaceName: sqlServerPENicName
    privateLinkServiceConnections: [
      {
        name: sqlServerPrivateEndPoint
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
          }
        }
      }
    ]
  }
  
  // Create Private DNS Zone Group 
  resource dns_group 'privateDnsZoneGroups@2020-11-01' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: sqlServerName
          properties: {
            privateDnsZoneId: privateDnsZonesql.id
          }
        }
      ]
    }
  }
}
