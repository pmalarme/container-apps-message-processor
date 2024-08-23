# Azure Container Apps Function

This is a simple Azure Function that processes a message from a queue and writes it to the log. To deploy this function, use the following command:

```bash
bash deploy.sh
```

This command will deploy the function to Azure Container Apps. The function will be triggered by a message in the `sbq-fabrikam-functions` queue.

Below are the parameters that can be configured in the `deploy.sh` script. You can override the default values by setting the environment variables using `export <parameter_name>=<value>`.

| Parameter Name                | Default Value                                      | Description                                      |
|-------------------------------|----------------------------------------------------|--------------------------------------------------|
| `RESOURCE_GROUP_NAME`         | `rg-fabrikam-function`                            | Name of the resource group                       |
| `LOCATION`                    | `eastus`                                           | Location for the resources                       |
| `CONTAINER_REGISTRY_NAME`     | `crfabrikamfunction<random-string>`               | Name of the container registry                   |
| `STORAGE_ACCOUNT_NAME`        | `stfabrikamfunction<random-string>`                              | Name of the storage account                      |
| `SERVICE_BUS_NAMESPACE_NAME`  | `sbns-fabrikam-function<random-string>`                          | Name of the service bus namespace                |
| `SERVICE_BUS_QUEUE_NAME`      | `sbq-fabrikam-function`                           | Name of the service bus queue                    |
| `CONTAINER_APP_ENVIRONMENT`   | `cae-fabrikam-function`                           | Name of the container app environment            |
| `FUNCTION_APP_NAME`           | `func-fabrikam-function`                          | Name of the function app                         |
| `IMAGE_NAME`                  | `fabrikam-function`                               | Name of the image                                |
| `IMAGE_TAG`                   | `1.0`                                           | Tag of the image                                 |

To test the function, you can send a message to the `sbq-fabrikam-functions` queue using `Service Bus Explorer` in the Azure portal. You can stream the log of the function in the Azure portal to see the message being processed.
