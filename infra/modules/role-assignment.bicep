param principalId string

param storageAccountName string
param storageRoleDefinitionId string

param serviceBusNamespaceName string
param serviceBusSenderRoleDefinitionId string
param serviceBusReceiverRoleDefinitionId string

param acrName string
param acrRoleDefinitionId string

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: serviceBusNamespaceName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource storageAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, principalId, storageRoleDefinitionId)
  scope: storage
  properties: {
    roleDefinitionId: storageRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusReceiverAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespace.id, principalId, serviceBusReceiverRoleDefinitionId)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: serviceBusReceiverRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusSenderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusNamespace.id, principalId, serviceBusSenderRoleDefinitionId)
  scope: serviceBusNamespace
  properties: {
    roleDefinitionId: serviceBusSenderRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
