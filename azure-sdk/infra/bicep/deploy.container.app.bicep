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
param containerAppLabel string = 'message-processor-azuresd'

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
@description('The name of the Azure Service Bus queue.')
param serviceBusQueueName string = 'sq-incoming-messages'

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

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  name: serviceBusQueueName
  parent: serviceBusNamespace
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

resource containerApp 'Microsoft.App/jobs@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration:{
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
      replicaRetryLimit: 3
      eventTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
        scale: {
          maxExecutions: 10
          minExecutions: 0
          pollingInterval: 30
          rules: [
            {
              name: 'scale-on-incoming-messages'
              type: 'azure-servicebus'
              auth: [
                {
                  secretRef: 'service-bus-connection-string'
                  triggerParameter: 'connection'
                }
              ]
              metadata: {
                namespace: serviceBusNamespace.name
                queueName: serviceBusQueue.name
                messageCount: '10'
              }
            }
          ]
        }
      }
      replicaTimeout: 60
      triggerType: 'Event'
    }
    template: {
      containers: [
        {
          name: containerAppLabel
          image:  '${containerRegistry.properties.loginServer}/azuresdk-function-examples:1.0'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'SERVICE_BUS_CONNECTION_STRING'
              secretRef: 'service-bus-connection-string'
            }
            {
              name: 'SERVICE_BUS_QUEUE_NAME'
              value: serviceBusQueueName
            }
          ]
        }
      ]
    }
  }
}
