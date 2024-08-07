# Azure SDK Container App Function

This is an Azure SDK-based Function that processes messages from a Service Bus queue and writes them to the log. To deploy this function, use the following command:

```bash
bash deploy.sh
```

This command will deploy the function to Azure Container Apps. The function will be triggered by messages in the Service Bus queue specified during deployment.

## Configuration Parameters

Below are the parameters that can be configured in the `deploy.sh` script. You can override the default values by setting the environment variables using `export <parameter_name>=<value>`.

| Parameter Name                | Default Value                   | Description                                      |
|-------------------------------|----------------------------------|--------------------------------------------------|
| `RESOURCE_GROUP_NAME`         | `rg-azuresdk-functions`          | Name of the resource group                       |
| `LOCATION`                    | `eastus`                         | Location for the resources                       |
| `ENVIRONMENT_NAME`            | `test`                           | Name of the environment                          |
| `CONTAINER_REGISTRY_NAME`     | `crazuresdkfunctions<random>`    | Name of the container registry                   |
| `SERVICE_BUS_NAMESPACE_NAME`  | `sbns-azuresdk-functions<random>`| Name of the Service Bus namespace                |
| `SERVICE_BUS_QUEUE_NAME`      | `sbq-azuresdk-functions`         | Name of the Service Bus queue                    |
| `CONTAINER_APP_ENVIRONMENT`   | `cae-azuresdk-functions`         | Name of the Container App environment            |
| `LOG_ANALYTICS_WORKSPACE_NAME`| `log-azuresdk-functions`         | Name of the Log Analytics workspace              |
| `DEPLOYMENT_NAME`             | `java-function-azuresdk-deployment` | Name of the main deployment                   |
| `CONTAINER_APP_DEPLOYMENT_NAME` | `azuresdk-container-app-deployment` | Name of the container app deployment        |
| `IMAGE_NAME`                  | `azuresdk-function-examples`     | Name of the Docker image                         |
| `IMAGE_TAG`                   | `1.0`                            | Tag of the Docker image                          |

Note: For `CONTAINER_REGISTRY_NAME` and `SERVICE_BUS_NAMESPACE_NAME`, a random 5-character string is appended to ensure uniqueness.