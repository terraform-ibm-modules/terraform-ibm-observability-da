#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to deploy the SLZ ROKS, which is a prerequisite for the Observability  ##
## Agents extension, after catalog validation has completed.                                                          ##
########################################################################################################################

set -e

DA_DIR="solutions/agents"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite SLZ ROKS CLUSTER and Observability Instances .."
  terraform init || exit 1
  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "region=\"${REGION}\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  region_var_name="region"
  cluster_id_var_name="cluster_id"
  cluster_id_value=$(terraform output -state=terraform.tfstate -raw workload_cluster_id)
  cluster_resource_group_id_var_name="cluster_resource_group_id"
  cluster_resource_group_id_value=$(terraform output -state=terraform.tfstate -raw cluster_resource_group_id)
  log_analysis_ingestion_key_var_name="log_analysis_ingestion_key"
  log_analysis_ingestion_key_value=$(terraform output -state=terraform.tfstate -raw log_analysis_ingestion_key)
  cloud_monitoring_access_key_var_name="cloud_monitoring_access_key"
  cloud_monitoring_access_key_value=$(terraform output -state=terraform.tfstate -raw cloud_monitoring_access_key)

  echo "Appending '${cluster_id_var_name}' and '${region_var_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg region_var_name "${region_var_name}" \
        --arg region_var_value "${REGION}" \
        --arg cluster_id_var_name "${cluster_id_var_name}" \
        --arg cluster_id_value "${cluster_id_value}" \
        --arg cluster_resource_group_id_var_name "${cluster_resource_group_id_var_name}" \
        --arg cluster_resource_group_id_value "${cluster_resource_group_id_value}" \
        --arg log_analysis_ingestion_key_var_name "${log_analysis_ingestion_key_var_name}" \
        --arg log_analysis_ingestion_key_value "${log_analysis_ingestion_key_value}" \
        --arg cloud_monitoring_access_key_var_name "${cloud_monitoring_access_key_var_name}" \
        --arg cloud_monitoring_access_key_value "${cloud_monitoring_access_key_value}" \
        '. + {($region_var_name): $region_var_value, ($cluster_id_var_name): $cluster_id_value, ($cluster_resource_group_id_var_name): $cluster_resource_group_id_value, ($log_analysis_ingestion_key_var_name): $log_analysis_ingestion_key_value, ($cloud_monitoring_access_key_var_name): $cloud_monitoring_access_key_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
