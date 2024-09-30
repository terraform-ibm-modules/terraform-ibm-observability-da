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
  cluster_crn = lookup([for cluster in module.landing_zone.cluster_data : cluster if strcontains(cluster.resource_group_name, "workload")][0], "crn", "")
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

##############################################################################
# Trusted Profile
##############################################################################

locals {
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logger-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "1.0.4"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Example Trusted Profile"

  trusted_profile_policies = [{
    roles = ["Editor"]
    resources = [{
      service = "logs-agent"
    }]
  }]

  trusted_profile_links = [{
    cr_type = "ROKS_SA"
    links = [{
      crn       = local.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}
