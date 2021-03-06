#!/bin/bash

set -e

if [[ -z "$INPUT_AWS_REGION" ]]; then
  echo "Set AWS region (aws_region) value."
  exit 1
fi

if [[ -z "$INPUT_SSM_PARAMETER" ]]; then
  echo "Set SSM parameter name (ssm_parameter) value."
  exit 1
fi

parameter_name="$INPUT_SSM_PARAMETER"
prefix="${INPUT_PREFIX:-aws_ssm_}"
jq_filter="$INPUT_JQ_FILTER"
simple_json="$INPUT_SIMPLE_JSON"

printenv

ssm_param=$(aws ssm get-parameter --region "$INPUT_AWS_REGION" --name "$parameter_name")

format_var_name () {
  echo "$1" | awk -v prefix="$prefix" -F. '{print prefix $NF}' | tr "[:upper:]" "[:lower:]"
}

if [ -n "$jq_filter" ] || [ -n "$simple_json" ]; then
  ssm_param_value=$(echo "$ssm_param" | jq '.Parameter.Value | fromjson')
  if [ -n "$simple_json" ] && [ "$simple_json" == "true" ]; then
    for p in $(echo "$ssm_param_value" | jq -r --arg v "$prefix" 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' ); do
      IFS='=' read -r var_name var_value <<< "$p"
      echo ::set-output name="$(format_var_name "$var_name")"::"$var_value"
    done
  else
    IFS=' ' read -r -a params <<< "$jq_filter"
    for var_name in "${params[@]}"; do
      var_value=$(echo "$ssm_param_value" | jq -r -c "$var_name")
      echo ::set-output name="$(format_var_name "$var_name")"::"$var_value"
    done
  fi
else
  var_name=$(echo "$ssm_param" | jq -r '.Parameter.Name' | awk -F/ '{print $NF}')
  var_value=$(echo "$ssm_param" | jq -r '.Parameter.Value')
  echo ::set-output name="$(format_var_name "$var_name")"::"$var_value"
fi

