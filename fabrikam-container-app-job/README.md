# Message Processor using Azure Container App Job

This is a job written in Java using the Azure SDK that processes messages from a Service Bus queue and writes them to the log. To deploy this function, use the following command:

```bash
bash deploy.sh
```

This command will deploy the function to Azure Container Apps. The function will be triggered by messages in the Service Bus queue specified during deployment.

## Configuration Parameters

Below are the parameters that can be configured in the `deploy.sh` script. You can override the default values by setting the environment variables using `export <parameter_name>=<value>`.

| Parameter Name                | Default Value                   | Description                                      |
|-------------------------------|----------------------------------|--------------------------------------------------|
| `RESOURCE_GROUP_NAME`         | `rg-fabrikam-job`          | Name of the resource group                       |
| `LOCATION`                    | `eastus`                         | Location for the resources                       |
| `ENVIRONMENT_NAME`            | `test`                           | Name of the environment                          |
| `CONTAINER_REGISTRY_NAME`     | `crfabrikamjob<random-string>`    | Name of the container registry                   |
| `SERVICE_BUS_NAMESPACE_NAME`  | `sbns-fabrikam-job<random-string>`| Name of the Service Bus namespace                |
| `SERVICE_BUS_QUEUE_NAME`      | `sbq-fabrikam-job`         | Name of the Service Bus queue                    |
| `CONTAINER_APP_ENVIRONMENT`   | `cae-fabrikam-job`         | Name of the Container App environment            |
| `LOG_ANALYTICS_WORKSPACE_NAME`| `log-fabrikam-job`         | Name of the Log Analytics workspace              |
| `DEPLOYMENT_NAME`             | `fabrikam-job-main-deployment` | Name of the main deployment                   |
| `CONTAINER_APP_DEPLOYMENT_NAME` | `fabrikam-job-containerapp-deployment` | Name of the container app deployment        |
| `IMAGE_NAME`                  | `fabrikam-job-example`     | Name of the Docker image                         |
| `IMAGE_TAG`                   | `1.0`                            | Tag of the Docker image                          |

Note: For `CONTAINER_REGISTRY_NAME` and `SERVICE_BUS_NAMESPACE_NAME`, a random 5-character string is appended to ensure uniqueness.