#!/bin/bash

################# Service Principal Login #################

# Check if required environment variables are set
if [ -z "$AZURE_APP_ID" ] || [ -z "$AZURE_PASSWORD" ] || [ -z "$AZURE_TENANT_ID" ] || [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
  echo "Missing one or more required environment variables."
  echo "You must export:"
  echo "  AZURE_APP_ID"
  echo "  AZURE_PASSWORD"
  echo "  AZURE_TENANT_ID"
  echo "  AZURE_SUBSCRIPTION_ID"
  exit 1
fi

# Login using Service Principal
echo "Logging into Azure using Service Principal..."
az login --service-principal \
  --username "$AZURE_APP_ID" \
  --password "$AZURE_PASSWORD" \
  --tenant "$AZURE_TENANT_ID" \
  --only-show-errors > /dev/null

if [ $? -ne 0 ]; then
  echo "Azure login with Service Principal failed."
  exit 1
fi

# Set subscription
echo "Setting Azure subscription to: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

if [ $? -ne 0 ]; then
  echo "Failed to set Azure subscription."
  exit 1
fi

################# Input Validation #################

# --- Parse direct environment argument ---
ENVIRONMENT="$1"
APPTYPE="$2"  # webapp or functionapp

# --- Validate input ---
if [ -z "$ENVIRONMENT" ] || [ -z "$APPTYPE" ]; then
  echo "Missing arguments."
  echo "Usage: ./delete_appinsights_instrumentation_key.sh <environment> <type>"
  echo "Examples:"
  echo "   ./delete_appinsights_instrumentation_key.sh qa webapp"
  echo "   ./delete_appinsights_instrumentation_key.sh prod functionapp"
  exit 1
fi

# --- Validate app type ---
if [[ "$APPTYPE" != "webapp" && "$APPTYPE" != "functionapp" ]]; then
  echo "Invalid type: must be 'webapp' or 'functionapp'"
  exit 1
fi

echo "Target environment: $ENVIRONMENT"
echo "Target type: $APPTYPE"

################# Set Prefix Based on Type #################

if [ "$APPTYPE" = "webapp" ]; then
  PREFIX="app-$ENVIRONMENT"
else
  PREFIX="func-$ENVIRONMENT"
fi

################# Fetch Applications with correct prefix #################

apps=$(az $APPTYPE list --query "[?starts_with(name, '$PREFIX')].{Name:name, ResourceGroup:resourceGroup}" -o tsv)

if [ -z "$apps" ]; then
    echo "No $APPTYPEs found starting with '$PREFIX'."
    exit 0
fi

################# Process Each Application #################

while IFS=$'\t' read -r appName resourceGroup
do
    echo "Processing $APPTYPE: $appName in Resource Group: $resourceGroup"

    # Delete the APPINSIGHTS_INSTRUMENTATIONKEY
    az $APPTYPE config appsettings delete \
        --name "$appName" \
        --resource-group "$resourceGroup" \
        --setting-names APPINSIGHTS_INSTRUMENTATIONKEY \
        --only-show-errors > /dev/null

    # Restart the app
    echo "Restarting $appName to apply changes..."
    az $APPTYPE restart --name "$appName" --resource-group "$resourceGroup"

    echo "Finished processing $appName"
done <<< "$apps"


echo "Script completed successfully for environment: $ENVIRONMENT and type: $APPTYPE"
