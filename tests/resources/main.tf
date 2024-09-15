##############################################################################
# SLZ ROKS Pattern
##############################################################################

module "landing_zone" {
  source                 = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone//patterns//roks//module?ref=v5.31.3"
  region                 = var.region
  prefix                 = var.prefix
  tags                   = var.resource_tags
  add_atracker_route     = false
  enable_transit_gateway = false
}

##############################################################################
# Observability Instances
##############################################################################

locals {
  cluster_resource_group_id = lookup([for cluster in module.landing_zone.cluster_data : cluster if strcontains(cluster.resource_group_name, "workload")][0], "resource_group_id", "")
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
  log_analysis_service_endpoints     = "private"
  log_analysis_instance_name         = "${var.prefix}-log-analysis"
  enable_platform_logs               = false
  cloud_monitoring_plan              = "graduated-tier"
  cloud_monitoring_service_endpoints = "private"
  cloud_monitoring_instance_name     = "${var.prefix}-cloud-monitoring"
  enable_platform_metrics            = false
  activity_tracker_provision         = false
}
