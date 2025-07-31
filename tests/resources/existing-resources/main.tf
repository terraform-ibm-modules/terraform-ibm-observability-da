##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create Cloud Object Storage instance and buckets
##############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.1.16"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  retention_enabled      = false # disable retention for test environments - enable for stage/prod
  kms_encryption_enabled = false
}

module "additional_cos_bucket" {
  source                   = "terraform-ibm-modules/cos/ibm"
  version                  = "10.1.16"
  region                   = var.region
  create_cos_instance      = false
  existing_cos_instance_id = module.cos.cos_instance_id
  bucket_name              = "${var.prefix}-bucket-at"
  kms_encryption_enabled   = false
}

module "cloud_log_buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "10.1.16"
  bucket_configs = [
    {
      bucket_name            = "${var.prefix}-data-bucket"
      add_bucket_name_suffix = true
      region_location        = var.region
      create_cos_instance    = false
      resource_instance_id   = module.cos.cos_instance_id
      kms_encryption_enabled = false
    },
    {
      bucket_name            = "${var.prefix}-metrics-bucket"
      add_bucket_name_suffix = true
      region_location        = var.region
      create_cos_instance    = false
      resource_instance_id   = module.cos.cos_instance_id
      kms_encryption_enabled = false
    }
  ]
}


module "cloud_monitoring" {
  source                  = "terraform-ibm-modules/cloud-monitoring/ibm"
  version                 = "1.6.0"
  region                  = var.region
  resource_group_id       = module.resource_group.resource_group_id
  instance_name           = var.prefix
  resource_tags           = var.resource_tags
  enable_platform_metrics = false
}

##############################################################################
# Event Notification
##############################################################################

module "event_notification_1" {
  source            = "terraform-ibm-modules/event-notifications/ibm"
  version           = "2.5.0"
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-en-1"
  tags              = var.resource_tags
  plan              = "standard"
  service_endpoints = "public"
  region            = var.region
}

module "event_notification_2" {
  source            = "terraform-ibm-modules/event-notifications/ibm"
  version           = "2.5.0"
  resource_group_id = module.resource_group.resource_group_id
  name              = "${var.prefix}-en-2"
  tags              = var.resource_tags
  plan              = "standard"
  service_endpoints = "public"
  region            = var.region
}
