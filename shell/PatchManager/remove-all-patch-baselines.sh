#!/bin/bash

region=$1

# Function to delete a patch baseline
delete_patch_baseline() {
  baseline_id=$1
  echo "Deleting patch baseline: $baseline_id"
  aws ssm delete-patch-baseline --baseline-id $baseline_id --region "${region}" --no-cli-pager
}

# Get a list of all patch baseline IDs and their default status.
baselines=$(aws ssm describe-patch-baselines \
            --query 'BaselineIdentities[*].[BaselineId, DefaultBaseline]' \
            --output text \
            --region "${region}")

# Iterate through each baseline
while IFS=$'\t' read -r baseline_id is_default; do
  if [ "$is_default" = "False" ]; then
    delete_patch_baseline $baseline_id
  fi
done <<< "$baselines"

echo "All non-default patch baselines deleted."
