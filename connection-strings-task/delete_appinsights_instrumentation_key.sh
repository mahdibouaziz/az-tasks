#!/bin/bash

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

# --- Set the prefix based on type ---
if [ "$APPTYPE" = "webapp" ]; then
  PREFIX="app-$ENVIRONMENT"
else
  PREFIX="func-$ENVIRONMENT"
fi

# --- Fetch apps starting with correct prefix ---
apps=$(az $APPTYPE list --query "[?starts_with(name, '$PREFIX')].{Name:name, ResourceGroup:resourceGroup}" -o tsv)

if [ -z "$apps" ]; then
    echo "No $APPTYPEs found starting with '$PREFIX'."
    exit 0
fi

# --- Process each app ---
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
