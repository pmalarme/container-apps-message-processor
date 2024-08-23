targetScope = 'resourceGroup'

/* -------------------------------------------------------------------------- */
/*                                 PARAMETERS                                 */
/* -------------------------------------------------------------------------- */

@description('The location of the resource group to which the resources in the template belong.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(15)
@description('The name of the workload.')
param workloadName string = 'java-function'

@allowed([
    'dev'
    'test'
    'prod'
])
@minLength(3)
@maxLength(5)
@description('The name of the environment.')
param environmentName string = 'dev'

@minLength(5)
@maxLength(50)
@description('The name of the container registry. Default is a combination of the workload name, environment name and a unique string.')
param containerRegistryName string = take('cr${replace(workloadName, '-', '')}${environmentName}${take(uniqueString(resourceGroup().id), 5)}', 50)

@description('Optional. The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string = 'log-${workloadName}-${environmentName}'

@minLength(2)
@maxLength(32)
@description('The name of the container registry. Default is a combination of \'cae\', the workload name and environment name.')
param containerAppsEnvironmentName string = 'cae-${workloadName}-${environmentName}'

@description('The name of the Service Bus namespace.')
param serviceBusNamespaceName string = take('sb-${workloadName}-${environmentName}${environmentName}${take(uniqueString(resourceGroup().id), 5)}', 50)

/* -------------------------------------------------------------------------- */
/*                              DEPLOYMENT TASKS                              */
/* -------------------------------------------------------------------------- */

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: containerRegistryName
  location: location
  sku: {
      name: 'Basic'
  }
  properties: {
      adminUserEnabled: true
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: containerAppsEnvironmentName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    zoneRedundant: false
    vnetConfiguration: {
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey:  logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
}

/* -------------------------------------------------------------------------- */
/*                                   OUTPUTS                                  */
/* -------------------------------------------------------------------------- */

@description('The name of the container registry.')
output containerRegistryName string = containerRegistry.name

@description('The name of the container apps environment.')
output containerAppsEnvironmentName string = containerAppsEnvironment.name

@description('The name of the Service Bus namespace.')
output serviceBusNamespaceName string = serviceBusNamespace.name
