#! /bin/bash

############################################################################################################
## This script is used by the catalog pipeline to pick an available region (one with no existing
## logs router tenant) and dynamically update solutions/logs-routing/catalogValidationValues.json
## before catalog validation runs, preventing tenant-already-exists collisions.
############################################################################################################

set -e

DA_DIR="solutions/logs-routing"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"

# All regions where IBM Logs Router tenants can be provisioned.
# Only one account-level tenant may exist per region.
SUPPORTED_REGIONS=(
  "au-syd"
  "br-sao"
  "ca-tor"
  "eu-de"
  "eu-es"
  "eu-gb"
  "jp-osa"
  "jp-tok"
  "us-east"
  "us-south"
)

(
  cwd=$(pwd)

  # $VALIDATION_APIKEY is available in the catalog runtime
  echo "Obtaining IAM token..."
  IAM_TOKEN=$(curl -s -X POST \
    "https://iam.cloud.ibm.com/identity/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=${VALIDATION_APIKEY}" \
    | jq -r '.access_token')

  if [[ -z "${IAM_TOKEN}" || "${IAM_TOKEN}" == "null" ]]; then
    echo "ERROR: Failed to obtain IAM token." >&2
    exit 1
  fi

  # Iterate regions and pick the first one that has no existing tenant
  SELECTED_REGION=""
  for region in "${SUPPORTED_REGIONS[@]}"; do
    echo "Checking region ${region} for an existing logs router tenant..."
    TENANT_COUNT=$(curl -s -X GET \
      "https://management.${region}.logs-router.cloud.ibm.com/v1/tenants" \
      -H "Authorization: Bearer ${IAM_TOKEN}" \
      -H "IBM-API-Version: 2024-03-01" \
      -H "Accept: application/json" \
      | jq '.tenants | length')

    if [[ "${TENANT_COUNT}" == "0" ]]; then
      SELECTED_REGION="${region}"
      echo "Selected region: ${SELECTED_REGION} (no existing tenant)"
      break
    else
      echo "  Region ${region} already has ${TENANT_COUNT} tenant(s); skipping."
    fi
  done

  if [[ -z "${SELECTED_REGION}" ]]; then
    echo "ERROR: All supported regions already have a logs router tenant. Cannot proceed with catalog validation." >&2
    exit 1
  fi

  tenant_region_key="tenant_region"
  tenant_region_value="${SELECTED_REGION}"

  echo "Updating '${tenant_region_key}' to '${tenant_region_value}' in ${JSON_FILE}.."

  cd "${cwd}"
  # tenant_configuration is a JSON-encoded string value, so gsub is used to substitute
  # the tenant_region field within that string without touching any other fields.
  jq -r --arg tenant_region_key "${tenant_region_key}" \
    --arg tenant_region_value "${tenant_region_value}" \
    '.tenant_configuration |= gsub("\"tenant_region\":[ ]*\"[^\"]*\""; "\"" + $tenant_region_key + "\": \"" + $tenant_region_value + "\"")' \
    "${JSON_FILE}" >tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation completed successfully"
)
