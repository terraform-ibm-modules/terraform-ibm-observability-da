#######################################################################################################################
# Local Variables
#######################################################################################################################
locals {
  prefix = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null
}

locals {

  # tflint-ignore: terraform_unused_declarations
  validate_existing_kms_inputs = (var.existing_cos_kms_key_crn != null && !var.skip_cos_kms_auth_policy) ? (var.existing_kms_instance_crn == null ? tobool("The existing_kms_instance_crn is not provided and is required to configure the COS - KMS authorization policy") : true) : true
  # tflint-ignore: terraform_unused_declarations
  validate_existing_cloud_monitoring = var.cloud_monitoring_provision && var.existing_cloud_monitoring_crn != null ? tobool("if cloud_monitoring_provision is set to true, then existing_cloud_monitoring_crn should be null and vice versa") : true
  # tflint-ignore: terraform_unused_declarations
  validate_cos_resource_group = var.existing_cos_instance_crn == null ? var.ibmcloud_cos_api_key != null && var.cos_resource_group_name == null ? tobool("if value for `ibmcloud_cos_api_key` is set, then `cos_resource_group_name` cannot be null") : true : true
  # tflint-ignore: terraform_unused_declarations
  validate_metrics_routing = var.enable_metrics_routing_to_cloud_monitoring ? ((var.existing_cloud_monitoring_crn != null || var.cloud_monitoring_provision) ? true : tobool("When `enable_metrics_routing_to_cloud_monitoring` is set to true, you must either set `cloud_monitoring_provision` as true or provide the `existing_cloud_monitoring_crn`.")) : true

  default_cos_region = var.cos_region != null ? var.cos_region : var.region

  cos_key_ring_name           = try("${local.prefix}-${var.cos_key_ring_name}", var.cos_key_ring_name)
  cos_key_name                = try("${local.prefix}-${var.cos_key_name}", var.cos_key_name)
  log_archive_cos_bucket_name = try("${local.prefix}-${var.log_archive_cos_bucket_name}", var.log_archive_cos_bucket_name)
  at_cos_target_bucket_name   = try("${local.prefix}-${var.at_cos_target_bucket_name}", var.at_cos_target_bucket_name)

  cos_instance_crn  = var.existing_cos_instance_crn != null ? var.existing_cos_instance_crn : length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_crn : null
  cos_instance_guid = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_guid : null : element(split(":", var.existing_cos_instance_crn), length(split(":", var.existing_cos_instance_crn)) - 3)

  # fetch KMS GUID from existing_kms_instance_crn if KMS resources are required
  existing_kms_guid = ((var.existing_cos_kms_key_crn != null && var.skip_cos_kms_auth_policy) ? null :
    ((length(coalesce(local.buckets_config, [])) == 0) ||
    (!var.manage_log_archive_cos_bucket && !var.enable_at_event_routing_to_cos_bucket && !var.cloud_logs_provision)) ? null :
  var.existing_kms_instance_crn != null ? module.kms_instance_crn_parser[0].service_instance : tobool("The CRN of the existing KMS instance is not provided."))

  # get KMS service type : Key Protect (kms) or Hyper Protect Crypto Services(hs-crypto)
  kms_service = var.existing_kms_instance_crn != null ? (
    can(regex(".*kms.*", var.existing_kms_instance_crn)) ? "kms" : (
      can(regex(".*hs-crypto.*", var.existing_kms_instance_crn)) ? "hs-crypto" : null
    )
  ) : null

  # fetch KMS region from existing_kms_instance_crn if KMS resources are required and existing_cos_kms_key_crn is not provided
  kms_region = ((length(coalesce(local.buckets_config, [])) != 0) ?
  (var.existing_cos_kms_key_crn == null ? module.kms_instance_crn_parser[0].region : null) : null)

  cos_kms_key_crn    = var.existing_cos_kms_key_crn != null ? var.existing_cos_kms_key_crn : length(coalesce(local.buckets_config, [])) != 0 ? module.kms[0].keys[format("%s.%s", local.cos_key_ring_name, local.cos_key_name)].crn : null
  parsed_kms_key_crn = local.cos_kms_key_crn != null ? split(":", local.cos_kms_key_crn) : []
  cos_kms_key_id     = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[9] : null
  cos_kms_scope      = length(local.parsed_kms_key_crn) > 0 ? local.parsed_kms_key_crn[6] : null
  kms_account_id     = length(local.parsed_kms_key_crn) > 0 ? split("/", local.cos_kms_scope)[1] : null

  cos_target_bucket_name     = var.existing_at_cos_target_bucket_name != null ? var.existing_at_cos_target_bucket_name : var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].bucket_name : null
  cos_resource_group_id      = var.cos_resource_group_name != null ? module.cos_resource_group[0].resource_group_id : module.resource_group.resource_group_id
  cos_target_bucket_endpoint = var.existing_at_cos_target_bucket_endpoint != null ? var.existing_at_cos_target_bucket_endpoint : var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].s3_endpoint_private : null
  cos_target_name            = try("${local.prefix}-cos-target", "cos-target")
  cloud_logs_target_name     = try("${local.prefix}-cloud-logs-target", "cloud-logs-target")
  at_cos_route_name          = try("${local.prefix}-at-cos-route", "at-cos-route")
  at_cloud_logs_route_name   = try("${local.prefix}-at-cloud-logs-route", "at-cloud-logs-route")
  metric_router_target_name  = try("${local.prefix}-cloud-monitoring-target", "cloud-monitoring-target")
  metric_router_route_name   = try("${local.prefix}-metric-routing-route", "metric-routing-route")

  default_metrics_router_route = var.enable_metrics_routing_to_cloud_monitoring ? [{
    name = local.metric_router_route_name
    rules = [{
      action = "send"
      targets = [{
        id = module.observability_instance.metrics_router_targets[local.metric_router_target_name].id
      }]
      inclusion_filters = []
    }]
  }] : []

  archive_bucket_config = var.manage_log_archive_cos_bucket ? {
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

  cloud_log_metrics_bucket_config = var.existing_cloud_logs_metrics_bucket_crn == null && var.cloud_logs_provision ? {
    class = var.cloud_log_metrics_bucket_class
    name  = local.cloud_log_metrics_bucket
    tag   = var.cloud_log_metrics_bucket_access_tag
  } : null

  bucket_retention_configs = merge(
    local.at_bucket_config != null ? { (local.at_cos_target_bucket_name) = var.at_cos_bucket_retention_policy } : null,
    local.cloud_log_data_bucket_config != null ? { (local.cloud_log_data_bucket) = var.cloud_log_data_bucket_retention_policy } : null
  )

  buckets_config = concat(
    local.archive_bucket_config != null ? [local.archive_bucket_config] : [],
    local.at_bucket_config != null ? [local.at_bucket_config] : [],
    local.cloud_log_data_bucket_config != null ? [local.cloud_log_data_bucket_config] : [],
    local.cloud_log_metrics_bucket_config != null ? [local.cloud_log_metrics_bucket_config] : []
  )

  archive_rule = length(local.buckets_config) != 0 ? {
    enable = true
    days   = 90
    type   = "Glacier"
  } : null

  expire_rule = length(local.buckets_config) != 0 ? {
    enable = true
    days   = 366
  } : null

  at_cos_route = var.enable_at_event_routing_to_cos_bucket ? [{
    route_name = local.at_cos_route_name
    locations  = ["*", "global"]
    target_ids = [module.observability_instance.activity_tracker_targets[local.cos_target_name].id]
  }] : []

  at_cloud_logs_route = var.enable_at_event_routing_to_cloud_logs ? [{
    route_name = local.at_cloud_logs_route_name
    locations  = ["*", "global"]
    target_ids = [module.observability_instance.activity_tracker_targets[local.cloud_logs_target_name].id]
  }] : []

  apply_auth_policy = (var.skip_cos_kms_auth_policy || (length(coalesce(local.buckets_config, [])) == 0)) ? 0 : 1
  at_routes         = concat(local.at_cos_route, local.at_cloud_logs_route)


  # Cloud Logs data bucket
  cloud_log_data_bucket = try("${local.prefix}-${var.cloud_log_data_bucket_name}", var.cloud_log_data_bucket_name)

  parsed_log_data_bucket_name         = var.existing_cloud_logs_data_bucket_crn != null ? split(":", var.existing_cloud_logs_data_bucket_crn) : []
  existing_cloud_log_data_bucket_name = length(local.parsed_log_data_bucket_name) > 0 ? local.parsed_log_data_bucket_name[1] : null

  # Cloud Logs metrics bucket
  cloud_log_metrics_bucket = try("${local.prefix}-${var.cloud_log_metrics_bucket_name}", var.cloud_log_metrics_bucket_name)

  parsed_log_metrics_bucket_name         = var.existing_cloud_logs_metrics_bucket_crn != null ? split(":", var.existing_cloud_logs_metrics_bucket_crn) : []
  existing_cloud_log_metrics_bucket_name = length(local.parsed_log_metrics_bucket_name) > 0 ? local.parsed_log_metrics_bucket_name[1] : null

  # https://github.ibm.com/GoldenEye/issues/issues/10928#issuecomment-93550079
  cloud_logs_existing_en_instances = concat(var.cloud_logs_existing_en_instances, var.existing_en_instance_crn != null ? [{
    instance_crn        = var.existing_en_instance_crn
    integration_name    = var.en_integration_name
    skip_en_auth_policy = var.skip_en_auth_policy
  }] : [])
}

#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (try("${local.prefix}-${var.resource_group_name}", var.resource_group_name)) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

module "cos_resource_group" {
  count = var.cos_resource_group_name != null ? 1 : 0
  providers = {
    ibm = ibm.cos
  }
  source              = "terraform-ibm-modules/resource-group/ibm"
  version             = "1.1.6"
  resource_group_name = try("${local.prefix}-${var.cos_resource_group_name}", var.cos_resource_group_name)
}

#######################################################################################################################
# Observability Instance
#######################################################################################################################

locals {
  cloud_monitoring_instance_name = try("${local.prefix}-${var.cloud_monitoring_instance_name}", var.cloud_monitoring_instance_name)
  cloud_logs_instance_name       = try("${local.prefix}-${var.cloud_logs_instance_name}", var.cloud_logs_instance_name)
  cloud_logs_data_bucket_crn     = var.existing_cloud_logs_data_bucket_crn != null ? var.existing_cloud_logs_data_bucket_crn : module.cos_bucket[0].buckets[local.cloud_log_data_bucket].bucket_crn
  cloud_log_metrics_bucket_crn   = var.existing_cloud_logs_metrics_bucket_crn != null ? var.existing_cloud_logs_metrics_bucket_crn : module.cos_bucket[0].buckets[local.cloud_log_metrics_bucket].bucket_crn
  cloud_logs_buckets             = [local.cloud_logs_data_bucket_crn, local.cloud_log_metrics_bucket_crn]
}

data "ibm_iam_account_settings" "iam_account_settings" {
}

resource "ibm_iam_authorization_policy" "cos_policy" {
  provider               = ibm.cos
  count                  = var.ibmcloud_cos_api_key != null && !var.skip_cloud_logs_cos_auth_policy ? length(local.cloud_logs_buckets) : 0
  source_service_account = data.ibm_iam_account_settings.iam_account_settings.account_id
  source_service_name    = "logs"
  roles                  = ["Writer"]
  description            = "Allow Cloud logs instances `Writer` access to the COS bucket with ID ${regex("bucket:(.*)", local.cloud_logs_buckets[count.index])[0]}, in the COS instance with ID ${regex(".*:(.*):bucket:.*", local.cloud_logs_buckets[count.index])[0]}."

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
    value    = regex(".*:(.*):bucket:.*", local.cloud_logs_buckets[count.index])[0]
  }

  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }

  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = regex("bucket:(.*)", local.cloud_logs_buckets[count.index])[0]
  }
}

module "en_crn_parser" {
  count   = length(local.cloud_logs_existing_en_instances)
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = local.cloud_logs_existing_en_instances[count.index]["instance_crn"]
}

module "cloud_monitoring_crn_parser" {
  count   = var.existing_cloud_monitoring_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_cloud_monitoring_crn
}

module "observability_instance" {
  depends_on        = [time_sleep.wait_for_atracker_cos_authorization_policy]
  source            = "terraform-ibm-modules/observability-instances/ibm"
  version           = "3.4.3"
  region            = var.region
  resource_group_id = module.resource_group.resource_group_id

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
  cloud_logs_policies          = var.cloud_logs_policies
  cloud_logs_data_storage = var.cloud_logs_provision ? {
    logs_data = {
      enabled              = true
      bucket_crn           = local.cloud_logs_data_bucket_crn
      bucket_endpoint      = var.existing_cloud_logs_data_bucket_endpoint != null ? var.existing_cloud_logs_data_bucket_endpoint : module.cos_bucket[0].buckets[local.cloud_log_data_bucket].s3_endpoint_direct
      skip_cos_auth_policy = var.ibmcloud_cos_api_key != null ? true : var.skip_cloud_logs_cos_auth_policy
    },
    metrics_data = {
      enabled              = true
      bucket_crn           = local.cloud_log_metrics_bucket_crn
      bucket_endpoint      = var.existing_cloud_logs_metrics_bucket_endpoint != null ? var.existing_cloud_logs_metrics_bucket_endpoint : module.cos_bucket[0].buckets[local.cloud_log_metrics_bucket].s3_endpoint_direct
      skip_cos_auth_policy = var.ibmcloud_cos_api_key != null ? true : var.skip_cloud_logs_cos_auth_policy
    }
  } : null
  cloud_logs_existing_en_instances = [for index, _ in local.cloud_logs_existing_en_instances : {
    en_instance_id      = module.en_crn_parser[index]["service_instance"]
    en_region           = module.en_crn_parser[index]["region"]
    en_integration_name = try("${local.prefix}-${local.cloud_logs_existing_en_instances[index]["integration_name"]}", local.cloud_logs_existing_en_instances[index]["integration_name"])
    skip_en_auth_policy = local.cloud_logs_existing_en_instances[index]["skip_en_auth_policy"]
  }]
  skip_logs_routing_auth_policy = var.skip_logs_routing_auth_policy
  logs_routing_tenant_regions   = var.logs_routing_tenant_regions

  # Activity Tracker
  at_cos_targets = var.enable_at_event_routing_to_cos_bucket ? [
    {
      bucket_name                       = local.cos_target_bucket_name
      endpoint                          = local.cos_target_bucket_endpoint
      instance_id                       = local.cos_instance_crn
      target_region                     = local.default_cos_region
      target_name                       = local.cos_target_name
      skip_atracker_cos_iam_auth_policy = var.ibmcloud_cos_api_key != null ? true : var.skip_at_cos_auth_policy
      service_to_service_enabled        = true
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

  # IBM Cloud Metrics Routing

  metrics_router_targets = var.enable_metrics_routing_to_cloud_monitoring ? [
    {
      destination_crn                     = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_crn : var.existing_cloud_monitoring_crn
      target_name                         = local.metric_router_target_name
      target_region                       = var.cloud_monitoring_provision ? var.region : module.cloud_monitoring_crn_parser[0].region
      skip_mrouter_sysdig_iam_auth_policy = false
    }
  ] : []

  metrics_router_routes = var.enable_metrics_routing_to_cloud_monitoring ? (length(var.metrics_router_routes) != 0 ? var.metrics_router_routes : local.default_metrics_router_route) : []
}

resource "time_sleep" "wait_for_atracker_cos_authorization_policy" {
  count           = var.ibmcloud_cos_api_key == null ? 0 : 1
  depends_on      = [ibm_iam_authorization_policy.atracker_cos]
  create_duration = "30s"
}
resource "ibm_iam_authorization_policy" "atracker_cos" {
  count                       = var.ibmcloud_cos_api_key != null && !var.skip_at_cos_auth_policy ? 1 : 0
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

# If existing KMS intance CRN passed, parse details from it
module "kms_instance_crn_parser" {
  count   = var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = (var.existing_cos_kms_key_crn != null || (length(coalesce(local.buckets_config, [])) == 0)) ? 0 : 1 # no need to create any KMS resources if passing an existing key, or bucket
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.19.7"
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

# Data source to account settings for retrieving COS cross account id
data "ibm_iam_account_settings" "iam_cos_account_settings" {
  provider = ibm.cos
}

# The auth policy is being created here instead of in COS module because of this limitation: https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/issues/8

# Create IAM Authorization Policy to allow COS to access KMS for the encryption key
resource "ibm_iam_authorization_policy" "policy" {
  count = local.apply_auth_policy
  # Conditionals with providers aren't possible, using ibm.kms as provider incase cross account is enabled
  provider                    = ibm.kms
  source_service_account      = data.ibm_iam_account_settings.iam_cos_account_settings.account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service} key ${local.cos_kms_key_id} from the instance ${local.existing_kms_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.existing_kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.cos_kms_key_id
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

module "cos_instance" {
  providers = {
    ibm = ibm.cos
  }
  count                    = var.existing_cos_instance_crn == null && length(coalesce(local.buckets_config, [])) != 0 ? 1 : 0 # no need to call COS module if consumer is using existing COS instance
  source                   = "terraform-ibm-modules/cos/ibm//modules/fscloud"
  version                  = "8.19.3"
  resource_group_id        = local.cos_resource_group_id
  create_cos_instance      = true
  cos_instance_name        = try("${local.prefix}-${var.cos_instance_name}", var.cos_instance_name)
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
  version = "8.19.3"
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
      retention_rule                = lookup(local.bucket_retention_configs, value.name, null)
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
