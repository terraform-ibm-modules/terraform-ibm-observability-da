#######################################################################################################################
# Local Variables
#######################################################################################################################

locals {
  archive_api_key = var.log_archive_api_key == null ? var.ibmcloud_api_key : var.log_archive_api_key

  cos_instance_crn            = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
  archive_cos_bucket_name     = var.existing_log_archive_cos_bucket_name != null ? var.existing_log_archive_cos_bucket_name : module.cos[0].buckets[var.log_archive_cos_bucket_name].bucket_name
  archive_cos_bucket_endpoint = var.existing_log_archive_cos_bucket_endpoint != null ? var.existing_log_archive_cos_bucket_endpoint : module.cos[0].buckets[var.log_archive_cos_bucket_name].s3_endpoint_private
  cos_kms_key_crn             = (var.existing_log_archive_cos_bucket_name != null && var.existing_at_cos_target_bucket_name != null) ? null : var.existing_cos_kms_key_crn != null ? var.existing_cos_kms_key_crn : module.kms[0].keys[format("%s.%s", var.cos_key_ring_name, var.cos_key_name)].crn

  cos_target_bucket_name     = var.existing_at_cos_target_bucket_name != null ? var.existing_at_cos_target_bucket_name : module.cos[0].buckets[var.at_cos_target_bucket_name].bucket_name
  cos_target_bucket_endpoint = var.existing_at_cos_target_bucket_endpoint != null ? var.existing_at_cos_target_bucket_endpoint : module.cos[0].buckets[var.at_cos_target_bucket_name].s3_endpoint_private

  bucket_config_1 = var.existing_log_archive_cos_bucket_name == null ? {
    class  = var.log_archive_cos_bucket_class
    name   = var.log_archive_cos_bucket_name
    tag    = var.archive_bucket_access_tags
    policy = var.skip_cos_kms_auth_policy
  } : null

  bucket_config_2 = var.existing_at_cos_target_bucket_name == null ? {
    class  = var.at_cos_target_bucket_class
    name   = var.at_cos_target_bucket_name
    tag    = var.at_cos_bucket_access_tags
    policy = var.skip_cos_kms_auth_policy == true ? false : true
  } : null

  bucket_config_map = var.existing_log_archive_cos_bucket_name == null ? (
    var.existing_at_cos_target_bucket_name == null ? [local.bucket_config_1, local.bucket_config_2] : [local.bucket_config_1]
    ) : (
    var.existing_at_cos_target_bucket_name == null ? [local.bucket_config_2] : null
  )

  archive_rule = (var.existing_log_archive_cos_bucket_name == null || var.existing_at_cos_target_bucket_name == null) ? {
    enable = true
    days   = 90
    type   = "Glacier"
  } : null

  expire_rule = (var.existing_log_archive_cos_bucket_name == null || var.existing_at_cos_target_bucket_name == null) ? {
    enable = true
    days   = 366
  } : null
}

#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.4"
  resource_group_name          = var.existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.existing_resource_group == true ? var.resource_group_name : null
}

#######################################################################################################################
# Observability Instance
#######################################################################################################################

module "observability_instance" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.11.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id
  enable_archive    = var.enable_log_archive
  ibmcloud_api_key  = local.archive_api_key
  # Log Analysis
  log_analysis_provision           = true
  log_analysis_instance_name       = var.log_analysis_instance_name
  log_analysis_plan                = var.log_analysis_plan
  log_analysis_tags                = var.log_analysis_tags
  log_analysis_service_endpoints   = var.log_analysis_service_endpoints
  log_analysis_cos_instance_id     = local.cos_instance_crn
  log_analysis_cos_bucket_name     = local.archive_cos_bucket_name
  log_analysis_cos_bucket_endpoint = local.archive_cos_bucket_endpoint
  # IBM Cloud Monitoring
  cloud_monitoring_provision         = true
  cloud_monitoring_instance_name     = var.cloud_monitoring_instance_name
  cloud_monitoring_plan              = var.cloud_monitoring_plan
  cloud_monitoring_tags              = var.cloud_monitoring_tags
  cloud_monitoring_service_endpoints = var.cloud_monitoring_service_endpoints

  # Activity Tracker
  activity_tracker_provision = false
  cos_targets = [
    {
      bucket_name                       = local.cos_target_bucket_name
      endpoint                          = local.cos_target_bucket_endpoint
      instance_id                       = local.cos_instance_crn
      target_region                     = var.cos_region
      target_name                       = "cos-target"
      skip_atracker_cos_iam_auth_policy = false
      service_to_service_enabled        = true
    }
  ]

  # Routes
  activity_tracker_routes = [
    {
      route_name = "at-route"
      locations  = ["*", "global"]
      target_ids = [
        module.observability_instance.activity_tracker_targets["cos-target"].id
      ]
    }
  ]
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (var.existing_cos_kms_key_crn != null || (var.existing_log_archive_cos_bucket_name != null && var.existing_at_cos_target_bucket_name != null)) ? 0 : 1 # no need to create any KMS resources if passing an existing key, or bucket
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.8.3"
  create_key_protect_instance = false
  region                      = var.kms_region
  existing_kms_instance_guid  = var.existing_kms_guid
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = var.cos_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = var.cos_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# COS
#######################################################################################################################

module "cos" {
  providers = {
    ibm = ibm.cos
  }
  count                    = (var.existing_log_archive_cos_bucket_name == null || var.existing_at_cos_target_bucket_name == null) ? 1 : 0 # no need to call COS module if consumer is passing existing COS bucket
  source                   = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version                  = "7.5.3"
  resource_group_id        = module.resource_group.resource_group_id
  create_cos_instance      = var.existing_cos_instance_crn == null ? true : false # don't create instance if existing one passed in
  create_resource_key      = false
  cos_instance_name        = var.cos_instance_name
  cos_tags                 = var.cos_instance_tags
  existing_cos_instance_id = var.existing_cos_instance_crn
  access_tags              = var.cos_instance_access_tags
  cos_plan                 = "standard"
  bucket_configs = [
    for value in local.bucket_config_map :
    {
      access_tags                   = value.tag
      bucket_name                   = value.name
      add_bucket_name_suffix        = var.add_bucket_name_suffix
      kms_encryption_enabled        = true
      kms_guid                      = var.existing_kms_guid
      kms_key_crn                   = local.cos_kms_key_crn
      skip_iam_authorization_policy = value.policy
      management_endpoint_type      = var.management_endpoint_type_for_bucket
      storage_class                 = value.class
      resource_instance_id          = local.cos_instance_crn
      region_location               = var.cos_region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      retention_rule                = null
    }
  ]
}
