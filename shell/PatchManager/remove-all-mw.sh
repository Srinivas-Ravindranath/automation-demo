#!/bin/bash

region=$1

# Function to delete a single maintenance window
delete_maintenance_window() {
  window_id=$1
  echo "Deleting maintenance window: $window_id"
  aws ssm delete-maintenance-window --window-id $window_id --region "${region}" --no-cli-pager
}

# Get a list of all maintenance window IDs
window_ids=$(aws ssm describe-maintenance-windows --query 'WindowIdentities[*].WindowId' --region "${region}" --output text)

# Iterate through each maintenance window ID and delete it
for window_id in $window_ids; do
  delete_maintenance_window $window_id
done

echo "All maintenance windows deleted."
