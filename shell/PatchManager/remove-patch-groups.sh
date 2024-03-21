#!/bin/bash


region=$1

# Function for safe deregistration (add your own criteria)
deregister_baseline() {
  baseline_id=$1
  patch_group=$2

  echo "Deregistering baseline: $baseline_id from patch group: $patch_group"
  aws ssm deregister-patch-baseline-for-patch-group \
      --baseline-id "$baseline_id" \
      --patch-group "$patch_group" \
      --region "${region}" \
      --no-cli-pager
}

# Get all patch groups
patch_groups=$(aws ssm describe-patch-groups --query 'Mappings[*].PatchGroup' --region "${region}" --output text)

# Process patch groups
for group in $patch_groups; do
  echo "Processing patch group: $group"

  # Get baseline ID associated with the patch group
  baseline_id=$(aws ssm get-patch-baseline-for-patch-group \
                --patch-group ${group} \
                --region "${region}")

  # Call the deregister function
  deregister_baseline $(jq -r '.BaselineId' <<< "${baseline_id}") "$group"

done
