#######################################################################################################################
# Local Variables
#######################################################################################################################

locals {

  # tflint-ignore: terraform_unused_declarations
  validate_log_analysis_provision = var.enable_at_event_routing_to_log_analysis && var.log_analysis_provision == false ? tobool("log_analysis_provision can't be false if enable_at_event_routing_to_log_analysis is true") : true
  # tflint-ignore: terraform_unused_declarations
  validate_existing_cloud_monitoring = var.cloud_monitoring_provision && var.existing_cloud_monitoring_crn != null ? tobool("if cloud_monitoring_provision is set to true, then existing_cloud_monitoring_crn should be null and vice versa") : true

  archive_api_key    = var.log_archive_api_key == null ? var.ibmcloud_api_key : var.log_archive_api_key
  default_cos_region = var.cos_region != null ? var.cos_region : var.region

  cos_key_ring_name           = var.prefix != null ? "${var.prefix}-${var.cos_key_ring_name}" : var.cos_key_ring_name
  cos_key_name                = var.prefix != null ? "${var.prefix}-${var.cos_key_name}" : var.cos_key_name
  log_archive_cos_bucket_name = var.prefix != null ? "${var.prefix}-${var.log_archive_cos_bucket_name}" : var.log_archive_cos_bucket_name
  at_cos_target_bucket_name   = var.prefix != null ? "${var.prefix}-${var.at_cos_target_bucket_name}" : var.at_cos_target_bucket_name

  cos_instance_crn            = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_crn : null
  existing_kms_guid           = ((var.existing_cloud_logs_data_bucket_crn != null && var.existing_log_archive_cos_bucket_name != null && var.existing_at_cos_target_bucket_name != null) || (!var.log_analysis_provision && !var.enable_at_event_routing_to_cos_bucket && !var.cloud_logs_provision)) ? null : var.existing_kms_instance_crn != null ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 3) : tobool("The CRN of the existing KMS is not provided.")
  cos_instance_guid           = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_guid : null : element(split(":", var.existing_cos_instance_crn), length(split(":", var.existing_cos_instance_crn)) - 3)
  archive_cos_bucket_name     = var.existing_log_archive_cos_bucket_name != null ? var.existing_log_archive_cos_bucket_name : var.log_analysis_provision ? module.cos_bucket[0].buckets[local.log_archive_cos_bucket_name].bucket_name : null
  archive_cos_bucket_endpoint = var.existing_log_archive_cos_bucket_endpoint != null ? var.existing_log_archive_cos_bucket_endpoint : var.log_analysis_provision ? module.cos_bucket[0].buckets[local.log_archive_cos_bucket_name].s3_endpoint_private : null
  cos_kms_key_crn             = ((var.existing_cloud_logs_data_bucket_crn != null && var.existing_log_archive_cos_bucket_name != null && var.existing_at_cos_target_bucket_name != null) || (!var.log_analysis_provision && !var.enable_at_event_routing_to_cos_bucket && !var.cloud_logs_provision)) ? null : var.existing_cos_kms_key_crn != null ? var.existing_cos_kms_key_crn : length(coalesce(local.buckets_config, [])) != 0 ? module.kms[0].keys[format("%s.%s", local.cos_key_ring_name, local.cos_key_name)].crn : null

  cos_target_bucket_name     = var.existing_at_cos_target_bucket_name != null ? var.existing_at_cos_target_bucket_name : var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].bucket_name : null
  cos_target_bucket_endpoint = var.existing_at_cos_target_bucket_endpoint != null ? var.existing_at_cos_target_bucket_endpoint : var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].s3_endpoint_private : null
  cos_target_name            = var.prefix != null ? "${var.prefix}-cos-target" : "cos-target"
  log_analysis_target_name   = var.prefix != null ? "${var.prefix}-log-analysis-target" : "log-analysis-target"
  cloud_logs_target_name     = var.prefix != null ? "${var.prefix}-cloud-logs-target" : "cloud-logs-target"
  at_cos_route_name          = var.prefix != null ? "${var.prefix}-at-cos-route" : "at-cos-route"
  at_log_analysis_route_name = var.prefix != null ? "${var.prefix}-at-log-analysis-route" : "at-log-analysis-route"
  at_cloud_logs_route_name   = var.prefix != null ? "${var.prefix}-at-cloud-logs-route" : "at-cloud-logs-route"

  archive_bucket_config = var.existing_log_archive_cos_bucket_name == null && var.log_analysis_provision ? {
    class = var.log_archive_cos_bucket_class
    name  = local.log_archive_cos_bucket_name
    tag   = var.archive_bucket_access_tags
  } : null

  at_bucket_config = var.existing_at_cos_target_bucket_name == null && var.enable_at_event_routing_to_cos_bucket ? {
    class = var.at_cos_target_bucket_class
    name  = local.at_cos_target_bucket_name
    tag   = var.at_cos_bucket_access_tags
  } : null

  cloud_log_data_bucket_config = var.existing_cloud_logs_data_bucket_crn == null && var.cloud_logs_provision ? {
    class = var.cloud_log_data_bucket_class
    name  = local.cloud_log_data_bucket
    tag   = var.cloud_log_data_bucket_access_tag
  } : null

  buckets_config = concat(
    local.archive_bucket_config != null ? [local.archive_bucket_config] : [],
    local.at_bucket_config != null ? [local.at_bucket_config] : [],
    local.cloud_log_data_bucket_config != null ? [local.cloud_log_data_bucket_config] : []
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

  kms_service = var.existing_kms_instance_crn != null ? (
    can(regex(".*kms.*", var.existing_kms_instance_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.existing_kms_instance_crn)) ? "hs-crypto" : null
    )
  ) : null

  kms_region = (length(coalesce(local.buckets_config, [])) != 0) ? (var.existing_cos_kms_key_crn == null ? element(split(":", var.existing_kms_instance_crn), length(split(":", var.existing_kms_instance_crn)) - 5) : null) : null
  at_cos_route = var.enable_at_event_routing_to_cos_bucket ? [{
    route_name = local.at_cos_route_name
    locations  = ["*", "global"]
    target_ids = [module.observability_instance.activity_tracker_targets[local.cos_target_name].id]
  }] : []

  at_log_analysis_route = var.enable_at_event_routing_to_log_analysis ? [{
    route_name = local.at_log_analysis_route_name
    locations  = ["*", "global"]
    target_ids = [module.observability_instance.activity_tracker_targets[local.log_analysis_target_name].id]
  }] : []

  at_cloud_logs_route = var.enable_at_event_routing_to_cloud_logs ? [{
    route_name = local.at_cloud_logs_route_name
    locations  = ["*", "global"]
    target_ids = [module.observability_instance.activity_tracker_targets[local.cloud_logs_target_name].id]
  }] : []

  at_routes = concat(local.at_cos_route, local.at_log_analysis_route, local.at_cloud_logs_route)

  cloud_log_data_bucket = var.prefix != null ? "${var.prefix}-${var.cloud_log_data_bucket_name}" : var.cloud_log_data_bucket_name

  parsed_log_data_bucket_name         = var.existing_cloud_logs_data_bucket_crn != null ? split(":", var.existing_cloud_logs_data_bucket_crn) : []
  existing_cloud_log_data_bucket_name = length(local.parsed_log_data_bucket_name) > 0 ? local.parsed_log_data_bucket_name[1] : null

  # Event Notifications
  parsed_existing_en_instance_crn = var.existing_en_instance_crn != null ? split(":", var.existing_en_instance_crn) : []
  existing_en_guid                = length(local.parsed_existing_en_instance_crn) > 0 ? local.parsed_existing_en_instance_crn[7] : null
  en_region                       = length(local.parsed_existing_en_instance_crn) > 0 ? local.parsed_existing_en_instance_crn[5] : null
  en_integration_name             = var.prefix != null ? "${var.prefix}-${var.en_integration_name}" : var.en_integration_name

}

#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

module "cos_resource_group" {
  providers = {
    ibm = ibm.cos
  }
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_cos_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.cos_resource_group_name}" : var.cos_resource_group_name) : null
  existing_resource_group_name = var.use_existing_cos_resource_group == true ? var.cos_resource_group_name : null
}

#######################################################################################################################
# Observability Instance
#######################################################################################################################

locals {
  parsed_existing_cloud_monitoring_crn = var.existing_cloud_monitoring_crn != null ? split(":", var.existing_cloud_monitoring_crn) : []
  existing_cloud_monitoring_guid       = length(local.parsed_existing_cloud_monitoring_crn) > 0 ? local.parsed_existing_cloud_monitoring_crn[7] : null

  log_analysis_instance_name     = var.prefix != null ? "${var.prefix}-${var.log_analysis_instance_name}" : var.log_analysis_instance_name
  cloud_monitoring_instance_name = var.prefix != null ? "${var.prefix}-${var.cloud_monitoring_instance_name}" : var.cloud_monitoring_instance_name
  cloud_logs_instance_name       = var.prefix != null ? "${var.prefix}-cloud-logs" : var.cloud_logs_instance_name
  cloud_logs_data_bucket_crn     = var.existing_cloud_logs_data_bucket_crn != null ? var.existing_cloud_logs_data_bucket_crn : module.cos_bucket[0].buckets[local.cloud_log_data_bucket].bucket_crn
}
data "ibm_iam_account_settings" "iam_account_settings" {
}

resource "ibm_iam_authorization_policy" "cos_policy" {
  provider               = ibm.cos
  count                  = var.skip_icl_cos_auth_policy ? 0 : 1
  source_service_account = data.ibm_iam_account_settings.iam_account_settings.account_id
  source_service_name    = "logs"
  roles                  = ["Writer"]
  description            = "Allow Cloud logs instances `Writer` access to the COS bucket with ID ${regex("bucket:(.*)", local.cloud_logs_data_bucket_crn)[0]}, in the COS instance with ID ${regex(".*:(.*):bucket:.*", local.cloud_logs_data_bucket_crn)[0]}."

  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = "cloud-object-storage"
  }

  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = data.ibm_iam_account_settings.iam_cos_account_settings.account_id
  }

  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = regex(".*:(.*):bucket:.*", local.cloud_logs_data_bucket_crn)[0]
  }

  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }

  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = regex("bucket:(.*)", local.cloud_logs_data_bucket_crn)[0]
  }
}

module "observability_instance" {
  depends_on = [time_sleep.wait_for_atracker_cos_authorization_policy]
  source     = "terraform-ibm-modules/observability-instances/ibm"
  version    = "2.19.1"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                      = var.region
  resource_group_id           = module.resource_group.resource_group_id
  log_analysis_enable_archive = var.log_analysis_enable_archive
  ibmcloud_api_key            = local.archive_api_key
  # Log Analysis
  log_analysis_provision           = var.log_analysis_provision
  log_analysis_instance_name       = local.log_analysis_instance_name
  log_analysis_plan                = var.log_analysis_plan
  log_analysis_tags                = var.log_analysis_tags
  log_analysis_service_endpoints   = var.log_analysis_service_endpoints
  log_analysis_cos_instance_id     = local.cos_instance_crn
  log_analysis_cos_bucket_name     = local.archive_cos_bucket_name
  log_analysis_cos_bucket_endpoint = local.archive_cos_bucket_endpoint
  enable_platform_logs             = var.enable_platform_logs
  # IBM Cloud Monitoring
  cloud_monitoring_provision         = var.cloud_monitoring_provision
  cloud_monitoring_instance_name     = local.cloud_monitoring_instance_name
  cloud_monitoring_plan              = var.cloud_monitoring_plan
  cloud_monitoring_tags              = var.cloud_monitoring_tags
  cloud_monitoring_service_endpoints = "public-and-private"
  enable_platform_metrics            = var.enable_platform_metrics

  # IBM Cloud Logs
  cloud_logs_provision         = var.cloud_logs_provision
  cloud_logs_instance_name     = local.cloud_logs_instance_name
  cloud_logs_plan              = "standard"
  cloud_logs_access_tags       = var.cloud_logs_access_tags
  cloud_logs_tags              = var.cloud_logs_tags
  cloud_logs_service_endpoints = "public-and-private"
  cloud_logs_retention_period  = var.cloud_logs_retention_period
  cloud_logs_data_storage = var.cloud_logs_provision ? {
    logs_data = {
      enabled              = true
      bucket_crn           = local.cloud_logs_data_bucket_crn
      bucket_endpoint      = var.existing_cloud_logs_data_bucket_endpoint != null ? var.existing_cloud_logs_data_bucket_endpoint : module.cos_bucket[0].buckets[local.cloud_log_data_bucket].s3_endpoint_direct
      skip_cos_auth_policy = true # we are handling auth policy creation of this module at line 149
    },
    metrics_data = {
      enabled         = false # Support tracked in https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/issues/170
      bucket_crn      = null
      bucket_endpoint = null
    }
  } : null
  cloud_logs_existing_en_instances = var.existing_en_instance_crn != null ? [{
    en_instance_id      = local.existing_en_guid
    en_region           = local.en_region
    en_instance_name    = local.en_integration_name
    skip_en_auth_policy = var.skip_en_auth_policy
  }] : []
  skip_logs_routing_auth_policy = var.skip_logs_routing_auth_policy
  logs_routing_tenant_regions   = var.logs_routing_tenant_regions

  # Activity Tracker
  activity_tracker_provision = false
  at_cos_targets = var.enable_at_event_routing_to_cos_bucket ? [
    {
      bucket_name                       = local.cos_target_bucket_name
      endpoint                          = local.cos_target_bucket_endpoint
      instance_id                       = local.cos_instance_crn
      target_region                     = local.default_cos_region
      target_name                       = local.cos_target_name
      skip_atracker_cos_iam_auth_policy = true # we are handling auth policy creation of this module at line 287
      service_to_service_enabled        = true
    }
  ] : []
  at_log_analysis_targets = var.enable_at_event_routing_to_log_analysis ? [
    {
      instance_id   = module.observability_instance.log_analysis_crn
      ingestion_key = module.observability_instance.log_analysis_ingestion_key
      target_region = var.region
      target_name   = local.log_analysis_target_name
    }
  ] : []

  at_cloud_logs_targets = var.enable_at_event_routing_to_cloud_logs ? [
    {
      instance_id   = module.observability_instance.cloud_logs_crn
      target_region = var.region
      target_name   = local.cloud_logs_target_name
    }
  ] : []

  # Routes
  activity_tracker_routes = local.at_routes
}

resource "time_sleep" "wait_for_atracker_cos_authorization_policy" {
  count           = var.ibmcloud_cos_api_key == null ? 0 : 1
  depends_on      = [ibm_iam_authorization_policy.atracker_cos]
  create_duration = "30s"
}
resource "ibm_iam_authorization_policy" "atracker_cos" {
  count                       = var.skip_at_cos_auth_policy ? 0 : 1
  provider                    = ibm.cos
  source_service_account      = data.ibm_iam_account_settings.iam_account_settings.account_id
  source_service_name         = "atracker"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = regex(".*:(.*)::", local.cos_instance_crn)[0]
  roles                       = ["Object Writer"]
  description                 = "Permit AT service Object Writer access to COS instance ${local.cos_instance_crn}"
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (var.existing_cos_kms_key_crn != null || (length(coalesce(local.buckets_config, [])) == 0)) ? 0 : 1 # no need to create any KMS resources if passing an existing key, or bucket
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.15.13"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = local.cos_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = local.cos_key_name
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

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.policy]
  count           = var.skip_cos_kms_auth_policy ? 0 : 1
  create_duration = "30s"
}

# Data source to account settings for retrieving cross account id
data "ibm_iam_account_settings" "iam_cos_account_settings" {
  provider = ibm.cos
}

# The auth policy is being created here instead of in COS module because of this limitation: https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/issues/8

# Create IAM Authorization Policy to allow COS to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "policy" {
  count = (var.skip_cos_kms_auth_policy || (length(coalesce(local.buckets_config, [])) == 0)) ? 0 : 1
  # Conditionals with providers aren't possible, using ibm.kms as provider incase cross account is enabled
  provider                    = ibm.kms
  source_service_account      = data.ibm_iam_account_settings.iam_cos_account_settings.account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  target_service_name         = local.kms_service
  target_resource_instance_id = local.existing_kms_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance with GUID ${local.cos_instance_guid} reader access to the kms_service instance GUID ${local.existing_kms_guid}"
}

module "cos_instance" {
  providers = {
    ibm = ibm.cos
  }
  count                    = var.existing_cos_instance_crn == null && length(coalesce(local.buckets_config, [])) != 0 ? 1 : 0 # no need to call COS module if consumer is using existing COS instance
  source                   = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version                  = "8.11.11"
  resource_group_id        = var.ibmcloud_cos_api_key != null ? module.cos_resource_group.resource_group_id : module.resource_group.resource_group_id
  create_cos_instance      = true
  cos_instance_name        = var.prefix != null ? "${var.prefix}-${var.cos_instance_name}" : var.cos_instance_name
  cos_tags                 = var.cos_instance_tags
  existing_cos_instance_id = var.existing_cos_instance_crn
  access_tags              = var.cos_instance_access_tags
  cos_plan                 = "standard"
}

module "cos_bucket" {
  depends_on = [time_sleep.wait_for_authorization_policy]
  providers = {
    ibm = ibm.cos
  }
  count   = length(coalesce(local.buckets_config, [])) != 0 ? 1 : 0 # no need to call COS module if consumer is using existing COS bucket
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "8.11.11"
  bucket_configs = [
    for value in local.buckets_config :
    {
      access_tags                   = value.tag
      bucket_name                   = value.name
      add_bucket_name_suffix        = var.add_bucket_name_suffix
      kms_encryption_enabled        = true
      kms_guid                      = local.existing_kms_guid
      kms_key_crn                   = local.cos_kms_key_crn
      skip_iam_authorization_policy = true
      management_endpoint_type      = var.management_endpoint_type_for_bucket
      storage_class                 = value.class
      resource_instance_id          = local.cos_instance_crn
      region_location               = local.default_cos_region
      force_delete                  = true
      archive_rule                  = local.archive_rule
      expire_rule                   = local.expire_rule
      retention_rule                = null
      metrics_monitoring = {
        usage_metrics_enabled   = true
        request_metrics_enabled = true
        # if DA is creating monitoring instance, use that. If its passing existing instance, use that. If neither, pass null, meaning metrics are sent to the instance associated to the container's location unless otherwise specified in the Metrics Router service configuration.
        metrics_monitoring_crn = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_crn : var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : null
      }
      activity_tracking = {
        read_data_events  = true
        write_data_events = true
        management_events = true
      }
    }
  ]
}
