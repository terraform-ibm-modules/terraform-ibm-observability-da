##############################################################################
# SLZ ROKS Pattern
##############################################################################

module "landing_zone" {
  source             = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone//patterns//roks//module?ref=v5.17.2"
  region             = var.region
  prefix             = var.prefix
  tags               = var.resource_tags
  add_atracker_route = false
}

##############################################################################
# Observability Instances
##############################################################################

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.11.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id              = local.cluster_resource_group_id
  region                         = var.region
  log_analysis_plan              = "7-day"
  cloud_monitoring_plan          = "graduated-tier"
  activity_tracker_provision     = false
  enable_platform_logs           = false
  enable_platform_metrics        = false
  log_analysis_instance_name     = "${var.prefix}-log-analysis"
  cloud_monitoring_instance_name = "${var.prefix}-cloud-monitoring"
}

##############################################################################
# Observability Agents
##############################################################################

locals {
  cluster_id                = lookup([for cluster in module.landing_zone.cluster_data : cluster if strcontains(cluster.resource_group_name, "workload")][0], "id", "")
  cluster_resource_group_id = lookup([for cluster in module.landing_zone.cluster_data : cluster if strcontains(cluster.resource_group_name, "workload")][0], "resource_group_id", "")
}

# data "ibm_container_cluster_config" "cluster_config" {
#   cluster_name_id   = local.cluster_id
#   resource_group_id = local.cluster_resource_group_id
# }

module "observability_agent" {
  # source      = "../../solutions/agents"
  ibmcloud_api_key             = var.ibmcloud_api_key
  source                       = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-da//solutions//agents?ref=sm-7651"
  cluster_id                   = local.cluster_id
  cluster_resource_group_id    = local.cluster_resource_group_id
  log_analysis_ingestion_key   = module.observability_instances.log_analysis_ingestion_key
  cloud_monitoring_access_key  = module.observability_instances.cloud_monitoring_access_key
  cluster_config_endpoint_type = "private"
}
