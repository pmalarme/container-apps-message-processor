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

#display_progress
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

RESOURCE_GROUP_NAME=${RESOURCE_GROUP_NAME:-"rg-fabrikam-function"}
LOCATION=${LOCATION:-"eastus"}
CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME:-"crfabrikamfunction$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)"}
STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME:-"stfabrikamfunction$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)"}
SERVICE_BUS_NAMESPACE_NAME=${SERVICE_BUS_NAMESPACE_NAME:-"sbns-fabrikam-function-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)"}
SERVICE_BUS_QUEUE_NAME=${SERVICE_BUS_QUEUE_NAME:-"sbq-fabrikam-function"}
CONTAINER_APP_ENVIRONMENT=${CONTAINER_APP_ENVIRONMENT:-"cae-fabrikam-function"}
FUNCTION_APP_NAME=${FUNCTION_APP_NAME:-"func-fabrikam-function"}

IMAGE_NAME=${IMAGE_NAME:-"fabrikam-function-example"}
IMAGE_TAG=${IMAGE_TAG:-"1.0"}

# Intro
display_progress "Deploying infrastructure for Fabrikam Functions..."
display_message INFO "Resource Group: $RESOURCE_GROUP_NAME"
display_message INFO "Location: $LOCATION"
display_message INFO "Container Registry Name: $CONTAINER_REGISTRY_NAME"
display_message INFO "Storage Account Name: $STORAGE_ACCOUNT_NAME"
display_message INFO "Service Bus Namespace Name: $SERVICE_BUS_NAMESPACE_NAME"
display_message INFO "Service Bus Queue Name: $SERVICE_BUS_QUEUE_NAME"
display_message INFO "Container App Environment: $CONTAINER_APP_ENVIRONMENT"
display_message INFO "Function App Name: $FUNCTION_APP_NAME"

display_blank_line

# Update Azure CLI
display_progress "Updating Azure CLI..."
az upgrade --yes --output none
display_message SUCCESS "  Azure CLI updated successfully."

# Install AZ CLI extensions for Azure Container Apps
display_progress "Installing Azure CLI extensions for Azure Container Apps..."
az extension add --name containerapp --upgrade -y
display_message SUCCESS "  Azure CLI extensions for Azure Container Apps installed successfully."

# Register Azure Providers
display_progress "Registering Azure providers..."
az provider register --namespace Microsoft.Web 
az provider register --namespace Microsoft.App 
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ServiceBus
display_message SUCCESS "  Azure providers registered successfully."
display_blank_line

# Create Resource Group
display_progress "Creating Resource Group..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --output none
display_message SUCCESS "  Resource Group created successfully."
display_blank_line

# Create Container Registry
display_progress "Creating Container Registry..."
az acr create --resource-group $RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --sku Basic --admin-enabled true --output none
display_message SUCCESS "  Container Registry created successfully."

display_progress "Retrieving Container Registry credentials..."
_credentialsJson=$(az acr credential show -n $CONTAINER_REGISTRY_NAME --query "[username, passwords[0].value]" -o json)
_username=$(echo $_credentialsJson | jq -r ".[0]")
_password=$(echo $_credentialsJson | jq -r ".[1]")
display_message SUCCESS "  Container Registry credentials retrieved successfully."
display_blank_line

# Create Storage Account
display_progress "Creating Storage Account..."
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard_LRS --output none
display_message SUCCESS "  Storage Account created successfully."
display_blank_line

# Create Service Bus Queue
display_progress "Creating Service Bus Namespace..."
az servicebus namespace create --name $SERVICE_BUS_NAMESPACE_NAME --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --sku Standard --output none
display_message SUCCESS "  Service Bus Namespace created successfully."

display_progress "Creating Service Bus Queue..."
az servicebus queue create --name $SERVICE_BUS_QUEUE_NAME --namespace-name $SERVICE_BUS_NAMESPACE_NAME --resource-group $RESOURCE_GROUP_NAME --output none
display_message SUCCESS "  Service Bus Queue created successfully."

display_progress "Retrieving Service Bus Connection String..."
SERVICE_BUS_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list --name RootManageSharedAccessKey --namespace-name $SERVICE_BUS_NAMESPACE_NAME --resource-group $RESOURCE_GROUP_NAME --query primaryConnectionString --output tsv)
display_message SUCCESS "  Service Bus Connection String retrieved successfully."
display_blank_line

# Create Container Apps Environment
display_progress "Creating Container Apps Environment..."
az containerapp env create --name $CONTAINER_APP_ENVIRONMENT --resource-group $RESOURCE_GROUP_NAME --location $LOCATION --enable-workload-profiles --output none
display_message SUCCESS "  Container Apps Environment created successfully."
display_blank_line

# Build and push Docker image
display_progress "Building Docker image..."
docker build -t $IMAGE_NAME:$IMAGE_TAG . > /dev/null 2>&1
display_message SUCCESS "  Docker image built successfully."

display_progress "Pushing Docker image to Container Registry..."
docker tag $IMAGE_NAME:$IMAGE_TAG $CONTAINER_REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG > /dev/null 2>&1
az acr login --name $CONTAINER_REGISTRY_NAME
docker push $CONTAINER_REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG > /dev/null 2>&1
display_message SUCCESS "  Docker image pushed to Container Registry successfully."
display_blank_line

# Create Function App
display_progress "Creating Function App..."
az functionapp create \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --environment $CONTAINER_APP_ENVIRONMENT \
  --workload-profile-name "Consumption" \
  --storage-account $STORAGE_ACCOUNT_NAME \
  --functions-version "4" \
  --runtime "Java" \
  --image $CONTAINER_REGISTRY_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG \
  --registry-server $CONTAINER_REGISTRY_NAME.azurecr.io \
  --registry-username $_username \
  --registry-password $_password \
  --min-replicas 1 \
  --max-replicas 10 \
  --output none
display_message SUCCESS "  Function App created successfully."

display_progress "Setting Service Bus connection string..."
az functionapp config appsettings set --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP_NAME --settings SERVICE_BUS_CONNECTION_STRING="$SERVICE_BUS_CONNECTION_STRING" --output none
display_message SUCCESS "  Service Bus connection string set successfully."
display_blank_line
