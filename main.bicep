// ============================================================================
// Main Bicep Template - Infrastructure Orchestration
// ============================================================================
// Deploys the following resources in order:
//   1. Managed Identity       (used by ACR, CAE, and Container App Jobs)
//   2. Log Analytics Workspace (provides logging for CAE)
//   3. Container Registry      (ACR with private endpoint)
//   4. Container Apps Env      (hosts Container App Jobs)
//   5. Container App Job 1     (Account Sync - accsync)
//   6. Container App Job 2     (SAH CB processor)
//   7. SQL Server              (with private endpoint)
//   8. SQL Database            (hosted on the SQL Server)
// ============================================================================

// --- Parameters ---

@description('Environment name (e.g., dev, sit, uat, prod)')
param env string = 'dev'

@description('SQL Server administrator login username')
@secure()
param sqlAdminLogin string

@description('SQL Server administrator login password')
@secure()
param sqlAdminPassword string

@description('Container image for the Account Sync job')
param containerImageAccSync string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Container image for the SAH CB job')
param containerImageSah string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// --- Variables ---

// Load environment-specific config and resource tags from JSON files
var params = loadJsonContent('variables/parameters.json')[env]
var tags = loadJsonContent('variables/tags.json')

// ============================================================================
// 1. Managed Identity
//    Created first because ACR, CAE, and Container App Jobs depend on it.
// ============================================================================

module managedIdentity 'modules/managed_identity.bicep' = {
  name: 'deploy-managed-identity'
  params: {
    location: params.location
    managedIdentityName: params.managedIdentity
    tags: tags
  }
}

// ============================================================================
// 2. Log Analytics Workspace
//    Provides monitoring and logging for the Container Apps Environment.
// ============================================================================

module logAnalytics 'modules/log_analytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    location: params.location
    logAnalyticsName: params.logAnalyticsName
    tags: tags
  }
}

// ============================================================================
// 3. Container Registry (ACR)
//    Stores container images. Uses private endpoint for secure access.
//    Depends on: Managed Identity
// ============================================================================

module containerRegistry 'modules/container_registry.bicep' = {
  name: 'deploy-container-registry'
  params: {
    env: env
    location: params.location
    acrName: params.acrName
    acrSku: params.acrSku
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    tags: tags
  }
}

// ============================================================================
// 4. Container Apps Environment
//    Hosts the Container App Jobs with consumption-based workload profiles.
//    Depends on: Managed Identity, Log Analytics
// ============================================================================

module containerAppsEnvironment 'modules/containerapps_environment.bicep' = {
  name: 'deploy-container-apps-environment'
  params: {
    location: params.location
    caeName: params.caeName
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    logAnalyticsCustomerId: logAnalytics.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: logAnalytics.outputs.logAnalyticsSharedKey
    tags: tags
  }
}

// ============================================================================
// 5. Container App Job - Account Sync
//    Manually-triggered job for account synchronization.
//    Depends on: Managed Identity, Container Apps Environment
// ============================================================================

module containerAppJobAccSync 'modules/containerapp_job1.bicep' = {
  name: 'deploy-containerapp-job-accsync'
  params: {
    env: env
    location: params.location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    containerImage: containerImageAccSync
    tags: tags
  }
}

// ============================================================================
// 6. Container App Job - SAH CB
//    Manually-triggered job for SAH CB processing.
//    Depends on: Managed Identity, Container Apps Environment
// ============================================================================

module containerAppJobSah 'modules/containerapp_job2.bicep' = {
  name: 'deploy-containerapp-job-sah'
  params: {
    env: env
    location: params.location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.containerAppsEnvironmentId
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    containerImage: containerImageSah
    tags: tags
  }
}

// ============================================================================
// 7. SQL Server
//    Deploys SQL Server with private endpoint for secure connectivity.
// ============================================================================

module sqlServer 'modules/sql_server.bicep' = {
  name: 'deploy-sql-server'
  params: {
    env: env
    location: params.location
    sqlServerName: params.sqlServerName
    tags: tags
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    virtualNetworkName: params.vnetname
    vnetResourceGroup: params.vnetResourceGroup
    subnetName: params.subnetName
    sqlServerPrivateEndPoint: params.sqlServerPrivateEndPoint
    privateDnsZoneSQLName: params.privateDnsZoneSQLName
  }
}

// ============================================================================
// 8. SQL Database
//    Creates the database on the SQL Server above.
//    Depends on: SQL Server
// ============================================================================

module sqlDatabase 'modules/sql_database.bicep' = {
  name: 'deploy-sql-database'
  dependsOn: [ sqlServer ]
  params: {
    location: params.location
    sqlServerName: params.sqlServerName
    sqlDataBaseName: params.sqlDataBaseName
    tags: tags
    sqlDbSKU: params.sqlDbSKU
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Managed Identity resource ID')
output managedIdentityId string = managedIdentity.outputs.managedIdentityId

@description('Managed Identity principal ID')
output managedIdentityPrincipalId string = managedIdentity.outputs.managedIdentityPrincipalId

@description('Container Registry login server')
output acrLoginServer string = containerRegistry.outputs.containerRegistryLoginServer

@description('Container Apps Environment ID')
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentId

@description('Container App Job - Account Sync name')
output containerAppJobAccSyncName string = containerAppJobAccSync.outputs.containerAppJobName

@description('Container App Job - SAH CB name')
output containerAppJobSahName string = containerAppJobSah.outputs.containerAppJobName
