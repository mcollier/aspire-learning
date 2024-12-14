targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

// @description('Specifies the name of the container app.')
// param containerAppName string = 'app-${uniqueString(resourceGroup().id)}'

@minLength(1)
@description('Primary location for all resources')
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@description('Specifies the name of the container app environment.')
param containerRegistryName string = ''

@description('Specifies the name of the container app environment.')
param containerAppEnvName string = ''

@description('Specifies the name of the log analytics workspace.')
param logAnalyticsWorkspaceName string = ''
param resourceGroupName string = ''

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  scope: rg
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    name: !empty(logAnalyticsWorkspaceName)
      ? logAnalyticsWorkspaceName
      : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
  }
}

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.8.1' = {
  scope: rg
  name: 'managedEnvironmentDeployment'
  params: {
    name: !empty(containerAppEnvName) ? containerAppEnvName : '${abbrs.appManagedEnvironments}${resourceToken}'
    logAnalyticsWorkspaceResourceId: workspace.outputs.resourceId
    zoneRedundant: false
  }
}

module acr 'br/public:avm/res/container-registry/registry:0.6.0' = {
  scope: rg
  name: 'containerRegistryDeployment'
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    publicNetworkAccess: 'Enabled'
    exportPolicyStatus: 'enabled'
  }
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  scope: rg
  name: 'userAssignedIdentityDeployment'
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  }
}

module userAssignedIdentityRoleAssignment 'modules/role-assignment.bicep' = {
  scope: rg
  name: 'userAssignedIdentityRoleAssignmentDeployment'
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionId: acrPullRole
    assignmentName: guid(rg.id, userAssignedIdentity.outputs.principalId, acrPullRole)
  }
}

module sbNamespace 'br/public:avm/res/service-bus/namespace:0.10.1' = {
  name: 'sbNamespaceDeployment'
  scope: rg
  params: {
    name: '${abbrs.serviceBusNamespaces}${resourceToken}'
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: 'storageAccountDeployment'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
  }
}

output RESOURCE_GROUP_NAME string = rg.name
output ACR_NAME string = acr.outputs.name
output USER_ASSIGNED_IDENTITY_NAME string = userAssignedIdentity.outputs.name
output MANAGED_ENVIRONMENT_NAME string = managedEnvironment.outputs.name
output SERVICE_BUS_ENDPOINT string = sbNamespace.outputs.name
