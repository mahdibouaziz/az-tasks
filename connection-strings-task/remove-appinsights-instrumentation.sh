#!/bin/bash

# --- Fetch web apps starting with 'app-qa' ---
echo "📄 Fetching Web Apps starting with 'app-qa'..."
apps=$(az webapp list --query "[?starts_with(name, 'app-qa')].{Name:name, ResourceGroup:resourceGroup}" -o tsv)

if [ -z "$apps" ]; then
    echo "⚠️ No Web Apps found starting with 'app-qa'."
    exit 0
fi

# --- Process each app ---
while IFS=$'\t' read -r appName resourceGroup
do
    echo "🔧 Processing App: $appName in Resource Group: $resourceGroup"

    # Delete the APPINSIGHTS_INSTRUMENTATIONKEY
    az webapp config appsettings delete \
        --name "$appName" \
        --resource-group "$resourceGroup" \
        --setting-names APPINSIGHTS_INSTRUMENTATIONKEY

    # Restart the app
    echo "🔄 Restarting $appName to apply changes..."
    az webapp restart --name "$appName" --resource-group "$resourceGroup"

    echo "✅ Finished processing $appName"

done <<< "$apps"

echo "🎉 Script completed successfully!"
