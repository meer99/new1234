/**
    This Bicep file deploys a new SQL DataBase.
**/

@description('Specifies the location for resource')
param location string

@description('Specifies the name of SQL DataBase')
param sqlDataBaseName string

@description('Specifies the tags for resources')
param tags object

@description('Specifies the name of SQL Server')
param sqlServerName string

@description('Specifies the sku for sql database')
param sqlDbSKU object


resource sqlDataBase 'Microsoft.Sql/servers/databases@2022-08-01-preview' = {
  name: '${sqlServerName}/${sqlDataBaseName}'
  location: location
  tags: tags
  sku: sqlDbSKU
  properties: {
    zoneRedundant: false
    readScale: 'Disabled'
    isLedgerOn: false
  }
}

