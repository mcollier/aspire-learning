param principalId string

var cognitiveServicesOpenAIUser = resourceId(
  'Microsoft.Authorization/roleDefinitions',
  '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
)

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: 'oai-mcollier'
}

resource openAiAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAi.id, principalId, cognitiveServicesOpenAIUser)
  scope: openAi
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUser
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
