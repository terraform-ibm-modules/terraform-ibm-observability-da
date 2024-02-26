##############################################################################
# Resource Group
##############################################################################
locals {
  log_analysis_instance_name     = var.log_analysis_instance_name != null ? var.log_analysis_instance_name : "logdna-${var.region}"
  cloud_monitoring_instance_name = var.cloud_monitoring_instance_name != null ? var.cloud_monitoring_instance_name : "sysdig-${var.region}"
  activity_tracker_instance_name = var.activity_tracker_instance_name != null ? var.activity_tracker_instance_name : "activity-tracker-${var.region}"
  log_analysis_tags              = var.log_analysis_tags != null ? var.log_analysis_tags : var.resource_tags
}

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

module "observability_instance" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.11.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  enable_archive    = var.enable_archive
  # Log Analysis
  log_analysis_instance_name     = local.log_analysis_instance_name
  log_analysis_plan              = var.log_analysis_plan
  log_analysis_tags              = local.log_analysis_tags
  log_analysis_manager_key_tags  = var.log_analysis_manager_key_tags
  log_analysis_access_tags       = var.log_analysis_access_tags
  log_analysis_service_endpoints = var.log_analysis_service_endpoints
  enable_platform_logs           = var.enable_platform_logs
  # IBM Cloud Monitoring
  cloud_monitoring_instance_name     = local.cloud_monitoring_instance_name
  cloud_monitoring_plan              = var.cloud_monitoring_plan
  cloud_monitoring_tags              = var.cloud_monitoring_tags
  cloud_monitoring_manager_key_tags  = var.cloud_monitoring_manager_key_tags
  cloud_monitoring_access_tags       = var.cloud_monitoring_access_tags
  cloud_monitoring_service_endpoints = var.cloud_monitoring_service_endpoints
  # Activity Tracker
  activity_tracker_instance_name     = local.activity_tracker_instance_name
  activity_tracker_plan              = var.activity_tracker_plan
  activity_tracker_tags              = var.activity_tracker_tags
  activity_tracker_manager_key_tags  = var.activity_tracker_manager_key_tags
  activity_tracker_access_tags       = var.activity_tracker_access_tags
  activity_tracker_service_endpoints = var.activity_tracker_service_endpoints
  enable_platform_metrics            = var.enable_platform_metrics
}
