#!/bin/bash

region=$1

# Function to delete a patch baseline
delete_patch_baseline() {
  baseline_id=$1
  echo "Deleting patch baseline: $baseline_id"
  aws ssm delete-patch-baseline --name $baseline_id --region "${region}" --no-cli-pager
}

# Get a list of all patch baseline IDs and their default status.
baselines=$(aws ssm describe-patch-baselines \
            --query 'BaselineIdentities[*].[BaselineId, DefaultBaseline]' \
            --output text \
            --region "${region}")

# Confirmation prompt
echo "This script will delete ALL non-default patch baselines in your account."
read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Operation cancelled."
  exit 1
fi

# Iterate through each baseline
while IFS=$'\t' read -r baseline_id is_default; do
  if [ "$is_default" = "False" ]; then
    delete_patch_baseline $baseline_id
  fi
done <<< "$baselines"

echo "All non-default patch baselines deleted."
