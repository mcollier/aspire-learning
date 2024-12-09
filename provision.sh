#!/bin/bash

# Variables
LOCATION="eastus"
TEMPLATE_FILE="infra/main.bicep"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
# Generate a unique deployment name using the current date
DEPLOYMENT_NAME="bicep-deployment-$(date +%Y%m%d%H%M%S)"

# Deploy Bicep template
az deployment sub create \
    --name $DEPLOYMENT_NAME \
    --location $LOCATION \
    --template-file $TEMPLATE_FILE \
    --parameters "infra/main.bicepparam"

echo "Deployment completed."