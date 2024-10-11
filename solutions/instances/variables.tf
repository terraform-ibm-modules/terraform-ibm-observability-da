########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Observability resources. Leave empty if the same account owns all the instances."
  sensitive   = true
  default     = null
}

variable "ibmcloud_cos_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a Cloud Object Storage (COS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the COS instance is in an account that's different from the one associated Observability resources. Leave empty if the same account owns all the instances."
  sensitive   = true
  default     = null
}


variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or existing resource group to provision resources in."
}

variable "cos_resource_group_name" {
  type        = string
  description = "The name of a new or existing resource group to provision COS instance in. If not specified, the 'resource_group_name' variable is used. Specify this if the COS instance is in an account that's different from the one associated Observability resources."
  default     = null
}

variable "region" {
  description = "The region where observability resources are created."
  type        = string
  default     = "us-south"

  validation {
    condition     = contains(["us-south", "us-east", "jp-osa", "jp-tok", "eu-de", "eu-es", "eu-gb", "au-syd"], var.region)
    error_message = "The specified region is not valid. Specify a valid region to create observability resources in."
  }
}

variable "prefix" {
  type        = string
  description = "The prefix to add to all resources that this solution creates."
  default     = null
}

##############################################################################
# IBM Cloud Logs
##############################################################################

variable "cloud_logs_provision" {
  description = "Set it to true to provision an IBM Cloud Logs instance"
  type        = bool
  default     = true
}

variable "cloud_logs_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Logs instance to create. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format."
  default     = "cloud-logs"
}

variable "cloud_logs_tags" {
  type        = list(string)
  description = "The resource tags that are associated with the IBM Cloud Logs instance (`Optional`, `array of strings`)."
  default     = []
}

variable "cloud_logs_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Cloud Logs instance. Maximum length: 128 characters. Possible characters are A-Z, 0-9, spaces, underscores, hyphens, periods, and colons. [Learn more](https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial)."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.cloud_logs_access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits."
  }
}
# https://github.ibm.com/GoldenEye/issues/issues/10928#issuecomment-93550079
variable "cloud_logs_existing_en_instances" {
  description = "A list of existing Event Notification instances to be integrated with the Cloud Logging service. Each object in the list represents an Event Notification instance, including its CRN, an optional name for the integration, and an optional flag to skip the authentication policy creation for the  Event Notification instance [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/tree/main/solutions/standard/DA-types.md#cloud_logs_existing_en_instances). This variable is intended for integrating a multiple Event Notifications instance to Cloud Logs. If you need to integrate only one instance, you may also use the `existing_en_instance_crn`, `en_integration_name` and `skip_en_auth_policy` variables instead."
  type = list(object({
    instance_crn        = string
    integration_name    = optional(string, "cloud-logs-en-integration")
    skip_en_auth_policy = optional(bool, false)
  }))
  default = []
}

variable "existing_en_instance_crn" {
  type        = string
  description = "The CRN of the existing event notification instance. This variable is intended for integrating a single Event Notifications instance to Cloud Logs. If you need to integrate multiple instances, use the `cloud_logs_existing_en_instances` variable instead."
  default     = null
}

variable "en_integration_name" {
  type        = string
  description = "The name of the event notification integration that gets created. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format. This variable is intended for integrating a single Event Notifications instance  to Cloud Logs. If you need to integrate multiple instances, use the `cloud_logs_existing_en_instances` variable instead."
  default     = "cloud-logs-en-integration"
}

variable "skip_en_auth_policy" {
  type        = bool
  description = "To skip creating auth policy that allows Cloud Logs 'Event Source Manager' role access in the existing event notification instance. This variable is intended for integrating a single Event Notifications instance  to Cloud Logs. If you need to integrate multiple instances, use the `cloud_logs_existing_en_instances` variable instead."
  default     = false
}

variable "cloud_logs_retention_period" {
  type        = number
  description = "The number of days IBM Cloud Logs will retain the logs data in priority insights. Possible Values: 7, 14, 30, 60, 90"
  default     = 7

  validation {
    condition     = contains([7, 14, 30, 60, 90], var.cloud_logs_retention_period)
    error_message = "The retention period must be one of the following values: 7, 14, 30, 60, or 90 days."
  }
}

variable "cloud_log_data_bucket_name" {
  type        = string
  default     = "cloud-logs-data-bucket"
  description = "The name of the Cloud Object Storage bucket to create to store cloud log data. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the bucket is prefixed to the value in the `<prefix>-value` format."
}

variable "existing_cloud_logs_data_bucket_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The crn of an existing bucket within the Cloud Object Storage instance to store IBM Cloud Logs data. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_cloud_logs_data_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The endpoint of an existing Cloud Object Storage bucket to use for storing the IBM Cloud Logs data. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "cloud_log_data_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned cloud logs Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.cloud_log_data_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`:  `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "cloud_log_data_bucket_access_tag" {
  type        = list(string)
  default     = []
  description = "A list of optional tags to add to the cloud log data object storage bucket."
}

variable "cloud_log_metrics_bucket_name" {
  type        = string
  default     = "cloud-logs-metrics-bucket"
  description = "The name of the Cloud Object Storage bucket to create to store cloud logs metrics. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the bucket is prefixed to the value in the `<prefix>-value` format."
}

variable "existing_cloud_logs_metrics_bucket_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The crn of an existing bucket within the Cloud Object Storage instance to store IBM Cloud Logs metrics. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_cloud_logs_metrics_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The endpoint of an existing Cloud Object Storage bucket to use for storing the IBM Cloud Logs metrics. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "cloud_log_metrics_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned cloud logs Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.cloud_log_metrics_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`:  `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "cloud_log_metrics_bucket_access_tag" {
  type        = list(string)
  default     = []
  description = "A list of optional tags to add to the cloud log metrics object storage bucket."
}

variable "skip_logs_routing_auth_policy" {
  description = "Whether to create an IAM authorization policy that permits Logs Routing Sender access to the IBM Cloud Logs."
  type        = bool
  default     = false
}

variable "enable_platform_logs" {
  type        = bool
  description = "Setting this to true will create a tenant in the same region that the Cloud Logs instance is provisioned to enable platform logs for that region. To send platform logs from other regions, you can explicitially specify a list of regions using the `logs_routing_tenant_regions` input. NOTE: You can only have 1 tenant per region in an account. If `log_analysis_provision` is set to true, this variable will also enable platform logs for the Log analysis instance."
  default     = true
}

variable "logs_routing_tenant_regions" {
  type        = list(any)
  default     = []
  description = "Pass a list of regions to create a tenant that is targetted to the Cloud Logs instance created by this module. To manage platform logs that are generated by IBM Cloud® services in a region of IBM Cloud, you must create a tenant in each region that you operate. Leave the list empty if you don't want to create any tenants."
  nullable    = false
}

##############################################################################
# Log Analysis Variables
##############################################################################

variable "log_analysis_provision" {
  description = "DEPRECATED: Set it to true to provision an IBM Cloud Logging instance. IBM Cloud Log Analysis is now deprecated and new instances cannot be provisioned after November 30, 2024, and all existing instances will be destroyed on March 30, 2025. For more information, see https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-getting-started"
  type        = bool
  default     = false
}

variable "log_analysis_instance_name" {
  type        = string
  description = "DEPRECATED: The name of the IBM Cloud Log Analysis instance to create. If a prefix input variable is specified, it's added to the value in the <prefix>-value format."
  default     = "log-analysis"
}

variable "log_analysis_plan" {
  type        = string
  description = "DEPRECATED: The Log Analysis plan to provision. Possible values: `7-day`, `14-day`, `30-day`, and `hipaa-30-day`."
  default     = "7-day"

  validation {
    condition     = can(regex("^lite$|^7-day$|^14-day$|^30-day$|^hipaa-30-day$", var.log_analysis_plan))
    error_message = "Specify one of the following values for the `log_analysis_plan`: `lite`, `7-day`, `14-day`, `30-day`, or `hipaa-30-day`."
  }
}

variable "log_analysis_service_endpoints" {
  description = "DEPRECATED: The type of endpoint for the Log Analysis instance. Possible values: `public`, `private`, `public-and-private`."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.log_analysis_service_endpoints)
    error_message = "The specified service endpoint is not valid. Specify a valid service endpoint to set for the IBM Log Analysis instance."
  }
}

variable "log_analysis_tags" {
  type        = list(string)
  description = "DEPRECATED: The tags that are associated with the IBM Cloud Logging instance (`Optional`, `array of strings`)."
  default     = []
}

variable "log_analysis_enable_archive" {
  type        = bool
  description = "DEPRECATED: Whether to enable archiving on Log Analysis instances. If set to true, `log_analysis_provision` must also be set to true."
  default     = true
}

variable "log_archive_api_key" {
  type        = string
  description = "DEPRECATED: The API key to use to configure archiving from Log Analysis to Object Storage. If not specified, the API key value in ibmcloud_api_key is used."
  sensitive   = true
  default     = null
}

variable "manage_log_archive_cos_bucket" {
  type        = bool
  default     = false
  description = "Log Analysis has been deprecated, however you can continue to manage the COS bucket that was used for Log Analysis log archiving by setting this input to true, even if `log_analysis_provision` or `log_analysis_enable_archive` have been set to false."
}

##############################################################################
# Activity Tracker Event Routing Variables
##############################################################################

variable "enable_at_event_routing_to_cos_bucket" {
  type        = bool
  description = "Whether to enable event routing from Activity Tracker to the Object Storage bucket."
  default     = true
}

variable "enable_at_event_routing_to_log_analysis" {
  type        = bool
  description = "Whether to enable event routing from Activity Tracker to Log Analysis. IBM Cloud Log Analysis is now deprecated and new instances cannot be provisioned after November 30, 2024, and all existing instances will be destroyed on March 30, 2025."
  default     = false
}

variable "enable_at_event_routing_to_cloud_logs" {
  type        = bool
  description = "Whether to enable event routing from Activity Tracker to Cloud Log."
  default     = true
}

##############################################################################
# Cloud Monitoring Variables
##############################################################################

variable "cloud_monitoring_provision" {
  description = "Whether to create an IBM cloud monitoring instance. Set to `false` if a CRN is specified in `existing_cloud_monitoring_crn`."
  type        = bool
  default     = true
}

variable "existing_cloud_monitoring_crn" {
  description = "The CRN of an IBM Cloud Monitoring instance. If specified, set the `cloud_monitoring_provision` variable to `false`."
  type        = string
  default     = null
}

variable "cloud_monitoring_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Monitoring instance to create. If the prefix variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
  default     = "cloud-monitoring"
}

variable "cloud_monitoring_plan" {
  type        = string
  description = "The IBM Cloud Monitoring plan to provision. Available values are `lite` and `graduated-tier`."
  default     = "graduated-tier"

  validation {
    condition     = can(regex("^lite$|^graduated-tier$", var.cloud_monitoring_plan))
    error_message = "Specify one of the following values for the `cloud_monitoring_plan`: `lite` or `graduated-tier`."
  }
}

variable "cloud_monitoring_tags" {
  type        = list(string)
  description = "The tags that are associated with the IBM Cloud Monitoring instance (`Optional`, `array of strings`)."
  default     = []
}

variable "enable_platform_metrics" {
  type        = bool
  description = "When set to `true`, the IBM Cloud Monitoring instance collects the platform metrics."
  default     = true
}

########################################################################################################################
# COS variables
########################################################################################################################

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Add a randomly generated suffix that is 4 characters in length, to the name of the newly provisioned Cloud Object Storage bucket. Do not use this suffix if you are passing the existing Cloud Object Storage bucket. To manage the name of the Cloud Object Storage bucket manually, use the `log_archive_cos_bucket_name` and `at_cos_target_bucket_name` variables."
  default     = true
}

variable "cos_region" {
  type        = string
  default     = null
  description = "The Cloud Object Storage region. If no value is provided, the value that is specified in the `region` input variable is used."
}

variable "cos_instance_name" {
  type        = string
  default     = "observability-cos"
  description = "The name of the Cloud Object Storage instance to create. If the prefix input variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
}

variable "cos_instance_tags" {
  type        = list(string)
  description = "A list of optional tags to add to a new Cloud Object Storage instance."
  default     = []
}

variable "cos_instance_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to a new Cloud Object Storage instance."
  default     = []
}

variable "log_archive_cos_bucket_name" {
  type        = string
  default     = "log-archive-cos-bucket"
  description = "The name of the Cloud Object Storage bucket to create to store log archive files. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
}

variable "at_cos_target_bucket_name" {
  type        = string
  default     = "at-events-cos-bucket"
  description = "The name of the Cloud Object Storage bucket to create for the Cloud Object Storage target to store AT events. Cloud Object Storage bucket names are globally unique. If the `add_bucket_name_suffix` variable is set to `true`, 4 random characters are added to this name to ensure that the name of the bucket is globally unique. If the prefix input variable is passed, the name of the instance is prefixed to the value in the `<prefix>-value` format."
}

variable "archive_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "A list of optional tags to add to the log archive Cloud Object Storage bucket."
}

variable "at_cos_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "A list of optional access tags to add to the IBM Cloud Activity Tracker Event Routing Cloud Object Storage bucket."
}

variable "log_archive_cos_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.log_archive_cos_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`: `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "at_cos_target_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.at_cos_target_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`:  `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an existing Cloud Object Storage instance. If a CRN is not specified, a new instance of Cloud Object Storage is created."
}

variable "existing_log_archive_cos_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket within the Cloud Object Storage instance in which to store log archive files. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_at_cos_target_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket within the Cloud Object Storage instance in which to store IBM Cloud Activity Tracker Event Routing. If an existing Cloud Object Storage bucket is not specified, a bucket is created."
}

variable "existing_log_archive_cos_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing Cloud Object Storage bucket endpoint to use for storing the log archive file. If an existing endpoint is not specified, the endpoint of the new Cloud Object Storage bucket is used."
}

variable "existing_at_cos_target_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing Cloud Object Storage bucket endpoint to use for setting up IBM Cloud Activity Tracker Event Routing. If an existing endpoint is not specified, the endpoint of the new Cloud Object Storage bucket is used."
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the created Cloud Object Storage instance to read the encryption key from the key management service (KMS) instance, set this variable to `true`. Before you can create an encrypted Cloud Object Storage bucket, an authorization policy must exist."
  default     = false
}

variable "skip_cloud_logs_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the IBM Cloud logs to write to the Cloud Object Storage bucket, set this variable to `true`."
  default     = false
}

variable "skip_at_cos_auth_policy" {
  type        = bool
  description = "To skip creating an IAM authorization policy that allows the Activity Traker to write to the Cloud Object Storage instance, set this variable to `true`."
  default     = false
}

variable "management_endpoint_type_for_bucket" {
  description = "The type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets (`public`, `private`, or `direct`). If you are using a private endpoint, make sure that you enable virtual routing and forwarding (VRF) in your account, and that the Terraform runtime can access the IBM Cloud Private network."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_bucket)
    error_message = "The specified `management_endpoint_type_for_bucket` is not valid. Specify a valid type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets."
  }
}

########################################################################################################################
# KMS variables
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of the key management service (KMS) that is used for the Cloud Object Storage bucket root key. If you are not using an existing KMS root key, you must specify this CRN. If the existing Cloud Object Storage bucket details are passed as an input, this value is not required."
}

variable "existing_cos_kms_key_crn" {
  type        = string
  default     = null
  description = "Optional. The CRN of an existing key management service (KMS) key to use to encrypt the Cloud Object Storage buckets that this solution creates. To create a key ring and key, pass a value for the `existing_kms_instance_crn` input variable. To use existing Cloud Object Storage buckets, pass a value for the `existing_log_archive_cos_bucket_name` and `existing_at_cos_target_bucket_name` input variables."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to use for communicating with the Key Protect or Hyper Protect Crypto Services instance. Possible values: `public`, `private`. Applies only if `existing_cos_kms_key_crn` is not specified."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "Valid values for the `kms_endpoint_type_value` are `public` or `private`. "
  }
}

variable "cos_key_ring_name" {
  type        = string
  default     = "observability-cos-key-ring"
  description = "The name of the key ring to create for the Cloud Object Storage bucket key. This name will be used by both the log archive bucket and the IBM Cloud Activity Tracker Cloud Object Storage bucket. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key ring is prefixed to the value in the `prefix-value` format."
}

variable "cos_key_name" {
  type        = string
  default     = "observability-cos-key"
  description = "The name of the key to create for the Cloud Object Storage bucket. This name will be used by both the log archive bucket and the IBM Cloud Activity Tracker Cloud Object Storage bucket. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key is prefixed to the value in the `prefix-value` format."
}
