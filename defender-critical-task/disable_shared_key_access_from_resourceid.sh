#!/bin/bash

CSV_FILE="storage_accounts_resource_ids.csv"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: File '$CSV_FILE' not found!"
  exit 1
fi

echo "Starting shared key access remediation using resourceId..."

# Skip header and process each line
tail -n +2 "$CSV_FILE" | while IFS= read -r resourceId
do
  # Clean whitespace
  resourceId=$(echo "$resourceId" | xargs)

  # Validate the resourceId format
  if [[ "$resourceId" != *"resourcegroups"* || "$resourceId" != *"storageaccounts"* ]]; then
    echo "Skipping invalid resourceId: $resourceId"
    continue
  fi

  # Extract resource group and storage account name from resourceId
  resourceGroup=$(echo "$resourceId" | awk -F"/" '{for (i=1; i<=NF; i++) if ($i=="resourcegroups") print $(i+1)}')
  storageAccount=$(echo "$resourceId" | awk -F"/" '{for (i=1; i<=NF; i++) if ($i=="storageaccounts") print $(i+1)}')

  echo "resource group: $reresourceGroup"
  echo "storage accunt: $storageAccount"
  echo "--------------------------------------"

done

