#!/bin/bash

# ---------------------------------------------------------------------------- #
#                                   FUNCTIONS                                  #
# ---------------------------------------------------------------------------- #

# display_message
# Displays a message with a specific color based on the message type
#
# Parameters:
#   $1: message_type - The type of message: ERROR, SUCCESS, WARNING, INFO, PROGRESS
#   $2: message - The message to display
#
# Usage: display_message <message_type> <message>
display_message() {
  local message_type=$1
  local message=$2

  case $message_type in
    "error")
      echo -e "\e[31mERROR: $message\e[0m"
      ;;
    "success")
      echo -e "\e[32m$message\e[0m"
      ;;
    "warning")
      echo -e "\e[33mWARNING: $message\e[0m"
      ;;
    "info")
      echo "INFO: $message"
      ;;
    "progress")
      echo -e "\e[34m$message\e[0m" # Blue for progress
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# display_progress
# Displays a progress message
#
# Parameters:
#   $1: message - The message to display
#
# Usage: display_progress <message>
display_progress() {
  local message=$1
  display_message progress "$message"
}

# display_blank_line
# Displays a blank line
#
# Usage: display_blank_line
display_blank_line() {
  echo ""
}

# ---------------------------------------------------------------------------- #
#                                  DEPLOYMENT                                  #
# ---------------------------------------------------------------------------- #

RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-"rg-quarkus-functions"}
LOCATION=${LOCATION:-"eastus"}
ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-"test"}

CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME:-"crquarkusfunctions$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)"}
SERVICE_BUS_NAMESPACE_NAME=${SERVICE_BUS_NAMESPACE_NAME:-"sbns-quarkus-functions"}
SERVICE_BUS_QUEUE_NAME=${SERVICE_BUS_QUEUE_NAME:-"sbq-quarkus-functions"}
CONTAINER_APP_ENVIRONMENT=${CONTAINER_APP_ENVIRONMENT:-"cae-quarkus-functions"}
LOG_ANALYTICS_WORKSPACE_NAME=${LOG_ANALYTICS_WORKSPACE_NAME:-"log-quarkus-functions"}
MAIN_SERVICE_TOPIC_NAME=${MAIN_SERVICE_TOPIC_NAME:-"sbt-incoming-messages"}
MESSAGES_ON_MAIN_TOPIC_FOR_QUARKUS_SUBSCRIPTION_NAME=${MESSAGES_ON_MAIN_TOPIC_FOR_QUARKUS_SUBSCRIPTION_NAME:-"sbts-all-incoming-messages-quarkus"}

DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-"java-function-quarkus-deployment"}
CONTAINER_APP_DEPLOYMENT_NAME=${CONTAINER_APP_DEPLOYMENT_NAME:-"quarkus-container-app-deployment"}

IMAGE_NAME=${IMAGE_NAME:-"quarkus-function-examples"}
IMAGE_TAG=${IMAGE_TAG:-"1.0"}

# Intro
display_progress "Deploying infrastructure for Java Function with Quarkus..."
display_message INFO "Resource Group: $RESOURCE_GROUP_NAME"
display_message INFO "Location: $LOCATION"
display_message INFO "Deployment Name: $DEPLOYMENT_NAME"
display_message INFO "Environment Name: $ENVIRONMENT_NAME"

display_blank_line

# Create Resource Group
display_progress "Creating Resource Group..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --output none
display_message SUCCESS "  Resource Group created successfully."
display_blank_line

# Deploy main Bicep template
display_progress "Deploying main Bicep template..."
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-file ./infra/bicep/main.bicep \
  --parameters environmentName=$ENVIRONMENT_NAME  containerRegistryName=$CONTAINER_REGISTRY_NAME containerAppsEnvironmentName=$CONTAINER_APP_ENVIRONMENT serviceBusNamespaceName=$SERVICE_BUS_NAMESPACE_NAME logAnalyticsWorkspaceName=$LOG_ANALYTICS_WORKSPACE_NAME \
  --output none
display_message SUCCESS "  Main Bicep template deployed successfully."
display_blank_line

# Retrieve deployment outputs
display_progress "Retrieving deployment outputs..."
CONTAINER_REGISTRY=$(az deployment group show --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME --query properties.outputs.containerRegistryName.value -o tsv)
CONTAINER_REGISTRY_FQDN="${CONTAINER_REGISTRY}.azurecr.io"
CONTAINER_APPS_ENVIRONMENT=$(az deployment group show --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME --query properties.outputs.containerAppsEnvironmentName.value -o tsv)
SERVICE_BUS=$(az deployment group show --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME --query properties.outputs.serviceBusNamespaceName.value -o tsv)
display_message SUCCESS "  Deployment outputs retrieved successfully."
display_blank_line

# Build and push Docker image
display_progress "Building Docker image..."
mvn clean install -D"quarkus.container-image.build"=true -DskipTests=true -D"quarkus.container-image.image"="$CONTAINER_REGISTRY_FQDN/$IMAGE_NAME:$IMAGE_TAG"
display_message SUCCESS "  Docker image built successfully."

display_progress "Pushing Docker image to Container Registry..."
az acr login --name $CONTAINER_REGISTRY
docker push $CONTAINER_REGISTRY_FQDN/$IMAGE_NAME:$IMAGE_TAG
display_message SUCCESS "  Docker image pushed to Container Registry successfully."
display_blank_line

# Deploy container app
display_progress "Deploying container app..."
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $CONTAINER_APP_DEPLOYMENT_NAME \
  --template-file ./infra/bicep/deploy.container.app.bicep \
  --parameters \
    environmentName=$ENVIRONMENT_NAME \
    containerAppsEnvironmentName=$CONTAINER_APPS_ENVIRONMENT \
    containerRegistryName=$CONTAINER_REGISTRY \
    serviceBusName=$SERVICE_BUS \
    mainServiceBusTopicName=$MAIN_SERVICE_TOPIC_NAME \
    allMessagesOnMainTopicForQuarkusSubscriptionName=$MESSAGES_ON_MAIN_TOPIC_FOR_QUARKUS_SUBSCRIPTION_NAME 
  --output none
display_message SUCCESS "  Container app deployed successfully."
display_blank_line

display_message SUCCESS "Deployment completed successfully."