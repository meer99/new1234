#!/bin/bash
# Deploy Bicep Infrastructure via Azure CLI
# Called from Azure DevOps release pipeline
# Variables ENVIRONMENT, RESOURCE_GROUP, SQL_ADMIN_LOGIN, SQL_ADMIN_PASSWORD
# are provided by the pipeline/release

set -euo pipefail

az deployment group create \
  --name "deploy-ccss" \
  --resource-group "$RESOURCE_GROUP" \
  --template-file main.bicep \
  --parameters env="$ENVIRONMENT" \
  --parameters sqlAdminLogin="$SQL_ADMIN_LOGIN" \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
  --output table

echo "Deployment completed!"
