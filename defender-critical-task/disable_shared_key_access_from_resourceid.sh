#!/bin/bash

CSV_FILE="storage_accounts_resource_ids.csv"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: File '$CSV_FILE' not found!"
  exit 1
fi

echo "Starting shared key access remediation using resourceId..."

# Skip header and process each line
tail -n +2 "$CSV_FILE" | cut -d',' -f1 | while IFS= read -r resourceId
do
  # Clean whitespace
  resourceId=$(echo "$resourceId" | xargs)

  # Validate the resourceId format
  if [[ "$resourceId" != *"resourcegroups"* || "$resourceId" != *"storageaccounts"* ]]; then
    echo "Skipping invalid resourceId: $resourceId"
    continue
  fi

  # Extract values (case-insensitive)
  resourceGroup=$(echo "$resourceId" | awk -F"/" '{for (i=1; i<=NF; i++) if (tolower($i)=="resourcegroups") print $(i+1)}')
  storageAccount=$(echo "$resourceId" | awk -F"/" '{for (i=1; i<=NF; i++) if (tolower($i)=="storageaccounts") print $(i+1)}')

  # echo "Resource Group : $resourceGroup"
  # echo "Storage Account: $storageAccount"
  # echo "--------------------------------------"

  echo "Updating storage account: $storageAccount (resource group: $resourceGroup)"

  # Execute the remediation command
  az storage account update \
    --name "$storageAccount" \
    --resource-group "$resourceGroup" \
    --allow-shared-key-access false \
    --only-show-errors > /dev/null

  
  if [[ $? -eq 0 ]]; then
    echo "Success: Shared key access disabled for '$storageAccount'"
  else
    echo "Error: Failed to update '$storageAccount'"
  fi

  echo "--------------------------------------"

done

echo "Remediation completed. Please verify in Microsoft Defender for Cloud."