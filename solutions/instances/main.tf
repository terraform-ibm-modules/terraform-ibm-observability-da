##############################################################################
# Resource Group
##############################################################################
locals {
  archive_api_key = var.archive_api_key == null ? var.ibmcloud_api_key : var.archive_api_key

  cos_instance_crn = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : module.cos[0].cos_instance_crn
  cos_bucket_name  = var.existing_cos_bucket_name != null ? var.existing_cos_bucket_name : module.cos[0].buckets[var.cos_bucket_name].bucket_name
  cos_kms_key_crn  = var.existing_cos_bucket_name != null ? null : var.existing_cos_kms_key_crn != null ? var.existing_cos_kms_key_crn : module.kms[0].keys[format("%s.%s", var.cos_key_ring_name, var.cos_key_name)].crn

  cos_target_instance_crn = var.existing_cos_target_instance_crn != null ? var.existing_cos_target_instance_crn : module.cos[0].cos_instance_crn
  cos_target_bucket_name  = var.existing_cos_target_bucket_name != null ? var.existing_cos_target_bucket_name : module.cos[0].buckets[var.cos_target_bucket_name].bucket_name
  cos_bucket_endpoint     = var.existing_cos_target_bucket_endpoint != null ? var.existing_cos_target_bucket_endpoint : module.cos[0].buckets[var.cos_target_bucket_name].s3_endpoint_private
  bucket_configs          = (var.existing_cos_bucket_name == null || var.existing_cos_target_bucket_name == null) ? concat([var.cos_bucket_name], [var.cos_target_bucket_name]) : null
  skip_auth_policy        = concat([var.skip_cos_kms_auth_policy], [true])

  archive_rule = var.existing_cos_bucket_name == null ? {
    enable = true
    days   = 90
    type   = "Glacier"
  } : null

  expire_rule = var.existing_cos_bucket_name == null ? {
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
  ibmcloud_api_key  = local.archive_api_key
  # Log Analysis
  log_analysis_provision           = true
  log_analysis_instance_name       = var.log_analysis_instance_name
  log_analysis_plan                = var.log_analysis_plan
  log_analysis_tags                = var.log_analysis_tags
  log_analysis_service_endpoints   = var.log_analysis_service_endpoints
  log_analysis_cos_instance_id     = module.cos[0].cos_instance_id
  log_analysis_cos_bucket_name     = local.cos_bucket_name
  log_analysis_cos_bucket_endpoint = local.cos_bucket_endpoint
  # Todo: Need to get the s3_endpoing exposed in the fscloud COS module
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
      endpoint                          = local.cos_bucket_endpoint
      instance_id                       = local.cos_target_instance_crn
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

# KMS root key for COS bucket
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = var.existing_cos_kms_key_crn != null || var.existing_cos_bucket_name != null ? 0 : 1 # no need to create any KMS resources if passing an existing key, or bucket
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.8.3"
  resource_group_id           = null # rg only needed if creating KP instance
  create_key_protect_instance = false
  region                      = var.kms_region
  existing_kms_instance_guid  = var.existing_kms_guid # currently using hpcs_south instance id as an input from common-permanent-resources.yaml
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
  count                    = (var.existing_cos_bucket_name == null || var.existing_cos_target_bucket_name == null) ? 1 : 0 # no need to call COS module if consumer is passing existing COS bucket
  source                   = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version                  = "7.5.0"
  resource_group_id        = module.resource_group.resource_group_id
  create_cos_instance      = var.existing_cos_instance_crn == null ? true : false # don't create instance if existing one passed in
  create_resource_key      = false
  cos_instance_name        = var.cos_instance_name
  cos_tags                 = var.cos_instance_tags
  existing_cos_instance_id = var.existing_cos_instance_crn
  access_tags              = var.cos_instance_access_tags
  cos_plan                 = "standard"
  bucket_configs = [
    for config in range(length(local.bucket_configs)) :
    {
      # Todo: Need to know the configuration for COS bucket
      # Are we going with this profile -> { retention_days = null, archive_days = "90", expiration_days = "366", version = false }
      access_tags                   = var.cos_bucket_access_tags
      bucket_name                   = local.bucket_configs[config]
      add_bucket_name_suffix        = var.add_bucket_name_suffix
      kms_encryption_enabled        = true
      kms_guid                      = var.existing_kms_guid
      kms_key_crn                   = local.cos_kms_key_crn
      skip_iam_authorization_policy = local.skip_auth_policy[config]
      management_endpoint_type      = var.management_endpoint_type_for_bucket
      storage_class                 = var.cos_bucket_class
      resource_instance_id          = local.cos_instance_crn
      region_location               = var.cos_region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      retention_rule                = null
    }
  ]
}
