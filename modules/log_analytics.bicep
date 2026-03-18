/**
    This Bicep file deploys a new Log Analytics WorkSpace.
    - The script defines params:
        - location
        - logAnalyticsName
    - LogAnalytics resource is of type 'Microsoft.OperationalInsights/workspaces@2022-10-01'.

**/

@description('Specifies the location for resource')
param location string

@description('Specifies the name of log analytics')
param logAnalyticsName string

@description('Specifies the tags for resources')
param tags object

//Create log analytics
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
}

output logAnalyticsID string = logAnalytics.id
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
@secure()
//#disable-next-line outputs-should-not-contain-secrets
output logAnalyticsSharedKey string = logAnalytics.listKeys().primarySharedKey

