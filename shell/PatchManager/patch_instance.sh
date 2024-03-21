#!/bin/bash

# TODO: Fix the command line arguments using flags

os_type=$1
msrc_severity=$2
classification=$3
products=$4
approve_after_days="${5:-7}"
maintenance_window_cron=$6
baseline_name=$7
region=$8

#show_help() {
#    echo "Usage: $0 [OPTIONS]"
#    echo "Options:"
#    echo "  -o, --os-type <type>               Required. Operating system type (e.g., Windows, Linux)"
#    echo "  -m, --msrc-severity <severity>     Required. MSRC severity (e.g., Critical, Important)"
#    echo "  -c, --classification <class>       Required. Classification (e.g., Security Updates, Updates)"
#    echo "  -p, --products <products>          Required. Comma-separated list of products"
#    echo "  -a, --approve-after <days>         Required. Approve after days"
#    echo "  -w, --window <cron>                Required. Maintenance window in cron format"
#    echo "  -b, --baseline-name <name>         Required. Name for the patch baseline"
#    echo "  -h, --help                         Display this help message"
#}
#
## Parse options with getopts
#while getopts ":o:m:c:p:a:w:b:h" option; do
#    case $option in
#        o) os_type=$OPTARG ;;
#        m) msrc_severity=$OPTARG ;;
#        c) classification=$OPTARG ;;
#        p) products=$OPTARG ;;
#        a) approve_after_days=$OPTARG ;;
#        w) maintenance_window_cron=$OPTARG ;;
#        b) baseline_name=$OPTARG ;;
#        h) show_help; exit 0 ;;
#        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
#        :) echo "Missing argument for -$OPTARG" >&2; exit 1 ;;
#    esac
#done

account_id=$(aws sts get-caller-identity | jq -r ".Account")


echo "Creating Patch Baseline for ${os_type}"
baseline_id=$(aws ssm create-patch-baseline \
  --name "${baseline_name}" \
  --operating-system "${os_type}" \
  --approval-rules  "PatchRules=[{PatchFilterGroup={PatchFilters=[{Key=PRODUCT,Values=[${products}]},{Key=MSRC_SEVERITY,Values=[${msrc_severity}]},{Key=CLASSIFICATION,Values=[${classification}]}]},ApproveAfterDays=${approve_after_days}}]""" \
  --description "Baseline containing all updates approved for ${os_type} system" \
  --region "${region}")
printf "Successfully created PatchBaseline for ${os_type}: \n ${baseline_id} \n"

echo "Registering the Patch Baseline into group *custom-patch-for--${os_type}*"
aws ssm register-patch-baseline-for-patch-group \
  --baseline-id $(jq -r '.BaselineId' <<< "${baseline_id}") \
  --patch-group "custom-patch-for-${os_type}" \
  --region "${region}" \
  --no-cli-pager
echo "Successfully created the Patch Baseline group custom-patch-for-${os_type}"

echo "Creating a batch pipeline maintenance window with cron ${maintenance_window_cron}"
window_id=$(aws ssm create-maintenance-window \
  --name "window-${os_type}" \
  --schedule "${maintenance_window_cron}" \
  --duration 1 \
  --cutoff 0 \
  --no-allow-unassociated-targets \
  --region "${region}")
printf "Successfully created maintenance window with cron ${maintenance_window_cron}, with window id: \n ${window_id} \n"


echo "Registering target with maintenance Window"
window_target_id=$(aws ssm register-target-with-maintenance-window \
    --window-id $(jq -r '.WindowId' <<< "${window_id}") \
    --targets "Key=tag:PatchGroup,Values=custom-patch-for-${os_type}" \
    --owner-information "custom-patch-for-${os_type}" \
    --resource-type "INSTANCE" \
    --region "${region}")
printf "Successfully Registered target with Maintenance Window with window target id: \n ${window_target_id} \n"

echo "Registering task with maintenance_window"
aws ssm register-task-with-maintenance-window \
    --window-id $(jq -r '.WindowId' <<< "${window_id}") \
    --targets "Key=WindowTargetIds,Values=$(jq -r '.WindowTargetId' <<< "${window_target_id}")" \
    --task-arn "AWS-RunPatchBaseline" \
    --service-role-arn "arn:aws:iam::${account_id}:role/MW-Role" \
    --task-type "RUN_COMMAND" \
    --max-concurrency 2 \
    --max-errors 1 \
    --priority 1 \
    --task-invocation-parameters "RunCommand={Parameters={Operation=Install}}" \
    --region "${region}" \
    --no-cli-pager
echo "Successfully registered task with maintenance_window"

echo "Describing the patch group status"
aws ssm describe-patch-group-state \
    --patch-group "custom-patch-for-${os_type}" \
    --region "${region}" \
    --no-cli-pager