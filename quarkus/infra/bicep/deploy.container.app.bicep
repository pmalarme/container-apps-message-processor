targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The location of the resource group to which the resources in the template belong.')
param location string = resourceGroup().location

@allowed([
    'dev'
    'test'
    'prod'
])
@minLength(3)
@maxLength(5)
@description('The name of the environment.')
param environmentName string = 'dev'

@minLength(1)
@maxLength(25)
@description('The label of the container apps')
param containerAppLabel string = 'message-processor-quarkus'

@minLength(2)
@maxLength(32)
@description('The name of the container app.')
param containerAppName string = take('ca-${containerAppLabel}-${environmentName}', 32)

@description('The name of the container app environment.')
param containerAppsEnvironmentName string

@description('The name of the container registry.')
param containerRegistryName string

@description('The name of the service bus.')
param serviceBusName string

@minLength(1)
@maxLength(260)  
@description('The name of the Azure Service Bus topic.')
param mainServiceBusTopicName string = 'sbt-incoming-messages'

@minLength(1)
@maxLength(50)
param allMessagesOnMainTopicForQuarkusSubscriptionName string = 'sbts-all-incoming-messages-quarkus'

/* -------------------------------------------------------------------------- */
/*                              DEPLOYMENT TASKS                              */
/* -------------------------------------------------------------------------- */

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource serviceBusNamespaceAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  name: 'RootManageSharedAccessKey'
  parent: serviceBusNamespace
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: mainServiceBusTopicName
  parent: serviceBusNamespace
}

resource serviceBusTopicSubscriptionAllMessagesForQuarkus 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  name: allMessagesOnMainTopicForQuarkusSubscriptionName
  parent: serviceBusTopic
  properties: {
    maxDeliveryCount: 100
    deadLetteringOnMessageExpiration: true
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' existing = {
  name: containerRegistryName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvironmentName
}

resource containerApp 'Microsoft.App/containerApps@2022-10-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration:{
      activeRevisionsMode: 'Single'
      secrets: [
        {
          name: 'service-bus-connection-string'
          value: serviceBusNamespaceAuthorizationRule.listKeys().primaryConnectionString
        }
        {
          name: 'container-registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'container-registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppLabel
          image:  '${containerRegistry.properties.loginServer}/quarkus-function-examples:1.0'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'QUARKUS_SERVICE_BUS_CONNECTION_STRING'
              secretRef: 'service-bus-connection-string'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 30
        rules: [
          {
            name: 'scale-on-incoming-messages'
            custom: {
              type: 'azure-servicebus'
              auth: [
                {
                  secretRef: 'service-bus-connection-string'
                  triggerParameter: 'connection'
                }
              ]
              metadata: {
                subscriptionName: serviceBusTopicSubscriptionAllMessagesForQuarkus.name
                topicName: serviceBusTopic.name
                messageCount: '10'
              }
            }
          }
        ]
      }
    }
  }
}
