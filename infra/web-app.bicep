targetScope = 'resourceGroup'

param imageName string
param managedEnvironmentName string
param userAssignedIdentityName string
param registryName string
param serviceBusConnectionString string
param serviceBusQueueName string

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: managedEnvironmentName
}

resource uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: userAssignedIdentityName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: registryName
}

module webApp 'br/public:avm/res/app/container-app:0.11.0' = {
  name: 'webAppDeployment'
  params: {
    environmentResourceId: environment.id
    name: 'web-app'
    managedIdentities: {
      userAssignedResourceIds: [uai.id]
    }
    scaleMinReplicas: 1
    scaleMaxReplicas: 5
    registries: [
      {
        identity: uai.id
        server: acr.properties.loginServer
      }
    ]
    ingressTargetPort: 8080
    containers: [
      {
        image: imageName
        name: 'web-app'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
        env: [
          {
            name: 'AZURE_CLIENT_ID'
            value: uai.properties.clientId
          }
          {
            name: 'AZURE_TENANT_ID'
            value: tenant().tenantId
          }
          {
            name: 'AZURE_SERVICE_BUS_QUEUE_NAME'
            value: serviceBusQueueName
          }
          {
            name: 'ConnectionStrings__service-bus'
            value: serviceBusConnectionString
          }
          {
            name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_EMIT_EXCEPTION_LOG_ATTRIBUTES'
            value: 'true'
          }
          {
            name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_EMIT_EVENT_LOG_ATTRIBUTES'
            value: 'true'
          }
          {
            name: 'OTEL_DOTNET_EXPERIMENTAL_OTLP_RETRY'
            value: 'in_memory'
          }
        ]
      }
    ]
  }
}
