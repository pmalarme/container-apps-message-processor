# Quarkus Azure Container Apps Function

This is a Quarkus-based Azure Function that processes messages from a Service Bus topic and writes them to the log. To deploy this function, use the following command:

```bash
bash deploy.sh
```

This command will deploy the function to Azure Container Apps. The function will be triggered by messages in the Service Bus topic specified during deployment.

## Configuration Parameters

Below are the parameters that can be configured in the `deploy.sh` script. You can override the default values by setting the environment variables using `export <parameter_name>=<value>`.

| Parameter Name                | Default Value                   | Description                                      |
|-------------------------------|----------------------------------|--------------------------------------------------|
| `RESOURCE_GROUP_NAME`         | `rg-quarkus-functions`           | Name of the resource group                       |
| `LOCATION`                    | `eastus`                         | Location for the resources                       |
| `ENVIRONMENT_NAME`            | `test`                           | Name of the environment                          |
| `CONTAINER_REGISTRY_NAME`     | `crquarkusfunctions<random>`     | Name of the container registry                   |
| `SERVICE_BUS_NAMESPACE_NAME`  | `sbns-quarkus-functions`         | Name of the Service Bus namespace                |
| `SERVICE_BUS_QUEUE_NAME`      | `sbq-quarkus-functions`          | Name of the Service Bus queue                    |
| `CONTAINER_APP_ENVIRONMENT`   | `cae-quarkus-functions`          | Name of the Container App environment            |
| `LOG_ANALYTICS_WORKSPACE_NAME`| `log-quarkus-functions`          | Name of the Log Analytics workspace              |
| `MAIN_SERVICE_TOPIC_NAME`     | `sbt-incoming-messages`          | Name of the main Service Bus topic               |
| `MESSAGES_ON_MAIN_TOPIC_FOR_QUARKUS_SUBSCRIPTION_NAME` | `sbts-all-incoming-messages-quarkus` | Name of the subscription for Quarkus on the main topic |
| `DEPLOYMENT_NAME`             | `java-function-quarkus-deployment` | Name of the main deployment                    |
| `CONTAINER_APP_DEPLOYMENT_NAME` | `quarkus-container-app-deployment` | Name of the container app deployment         |
| `IMAGE_NAME`                  | `quarkus-function-examples`      | Name of the Docker image                         |
| `IMAGE_TAG`                   | `1.0`                            | Tag of the Docker image                          |