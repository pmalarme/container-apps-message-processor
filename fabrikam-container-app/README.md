# Message Processor using Azure Container App

This is a message processor application written in Java using Quarkus and deployed in an Azure Container App that processes messages from a Service Bus queue and writes them to the log. To deploy this application, use the following command:

```bash
bash deploy.sh
```

This command will deploy the application to Azure Container Apps. The message processor will be triggered by messages in the Service Bus queue specified during deployment.

## Configuration Parameters

Below are the parameters that can be configured in the `deploy.sh` script. You can override the default values by setting the environment variables using `export <parameter_name>=<value>`.

| Parameter Name                | Default Value                   | Description                                      |
|-------------------------------|----------------------------------|--------------------------------------------------|
| `RESOURCE_GROUP_NAME`         | `rg-fabrikam-containerapp`           | Name of the resource group                       |
| `LOCATION`                    | `eastus`                         | Location for the resources                       |
| `ENVIRONMENT_NAME`            | `test`                           | Name of the environment                          |
| `CONTAINER_REGISTRY_NAME`     | `crfabrikamcontainerapp<random-string>`     | Name of the container registry                   |
| `SERVICE_BUS_NAMESPACE_NAME`  | `sbns-fabrikam-containerapp<random-string>`         | Name of the Service Bus namespace                |
| `SERVICE_BUS_QUEUE_NAME`      | `sbq-fabrikam-containerapp`          | Name of the Service Bus queue                    |
| `CONTAINER_APP_ENVIRONMENT`   | `cae-fabrikam-containerapp`          | Name of the Container App environment            |
| `LOG_ANALYTICS_WORKSPACE_NAME`| `log-fabrikam-containerapp`          | Name of the Log Analytics workspace              |
| `SERVICE_BUS_QUEUE_NAME`     | `sbq-fabrikam-containerapp`          | Name of the main Service Bus topic               |
| `DEPLOYMENT_NAME`             | `fabrikam-containerapp-main-deployment` | Name of the main deployment                    |
| `CONTAINER_APP_DEPLOYMENT_NAME` | `fabrikam-containerapp-containerapp-deployment` | Name of the container app deployment         |
| `IMAGE_NAME`                  | `fabrikam-containerapp-example`      | Name of the Docker image                         |
| `IMAGE_TAG`                   | `1.0`                            | Tag of the Docker image                          |