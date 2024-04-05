########################################################################################################################
# Provider config
########################################################################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

locals {
  at_endpoint = var.log_analysis_service_endpoints == "private" ? "https://api.${var.log_analysis_service_endpoints}.${var.region}.logging.cloud.ibm.com" : "https://api.${var.region}.logging.cloud.ibm.com"
}

provider "logdna" {
  alias      = "at"
  servicekey = module.observability_instance.activity_tracker_resource_key != null ? module.observability_instance.activity_tracker_resource_key : ""
  url        = local.at_endpoint
}

provider "logdna" {
  alias      = "ld"
  servicekey = module.observability_instance.log_analysis_resource_key != null ? module.observability_instance.log_analysis_resource_key : ""
  url        = local.at_endpoint
}

provider "ibm" {
  alias            = "cos"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.cos_region
}

provider "ibm" {
  alias            = "kms"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = local.kms_region
}
