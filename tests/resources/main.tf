##############################################################################
# SLZ ROKS Pattern
##############################################################################

module "landing_zone" {
  source                              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone//patterns//roks//module?ref=v6.0.1"
  region                              = var.region
  prefix                              = var.prefix
  tags                                = var.resource_tags
  add_atracker_route                  = false
  enable_transit_gateway              = false
  cluster_force_delete_storage        = true
  verify_cluster_network_readiness    = false
  use_ibm_cloud_private_api_endpoints = false
  ignore_vpcs_for_cluster_deployment  = ["management"]
}

##############################################################################
# Observability Instances
##############################################################################

locals {
  cluster_resource_group_id = module.landing_zone.cluster_data["${var.prefix}-workload-cluster"].resource_group_id
}

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.18.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id                  = local.cluster_resource_group_id
  region                             = var.region
  log_analysis_plan                  = "7-day"
  log_analysis_service_endpoints     = "public-and-private"
  log_analysis_instance_name         = "${var.prefix}-log-analysis"
  enable_platform_logs               = false
  cloud_monitoring_plan              = "graduated-tier"
  cloud_monitoring_service_endpoints = "public-and-private"
  cloud_monitoring_instance_name     = "${var.prefix}-cloud-monitoring"
  enable_platform_metrics            = false
  activity_tracker_provision         = false
}
