########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or existing resource group to provision resources to. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format."
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
  description = "Optional. The prefix to append to all resources that this solution creates."
  default     = null
}

##############################################################################
# Log Analysis Variables
##############################################################################

variable "log_analysis_provision" {
  description = "Set it to true to provision an IBM Cloud Logging instance"
  type        = bool
  default     = true
}

variable "log_analysis_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Logging instance to create. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format."
  default     = "log-analysis"
}

variable "log_analysis_plan" {
  type        = string
  description = "The IBM Cloud Logging plan to provision. Available values are `7-day`, `14-day`, `30-day`, and `hipaa-30-day`."
  default     = "7-day"

  validation {
    condition     = can(regex("^lite$|^7-day$|^14-day$|^30-day$|^hipaa-30-day$", var.log_analysis_plan))
    error_message = "Specify one of the following values for the `log_analysis_plan`: `lite`, `7-day`, `14-day`, `30-day`, or `hipaa-30-day`."
  }
}

variable "log_analysis_service_endpoints" {
  description = "The type of the service endpoint that will be set for the IBM Log Analysis instance."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.log_analysis_service_endpoints)
    error_message = "The specified service endpoint is not valid. Specify a valid service endpoint to set for the IBM Log Analysis instance."
  }
}

variable "log_analysis_tags" {
  type        = list(string)
  description = "The tags that are associated with the IBM Cloud Logging instance (`Optional`, `array of strings`)."
  default     = []
}

variable "enable_log_archive" {
  type        = bool
  description = "Enable the archive file for the IBM Log Analysis instance."
  default     = true
}

variable "log_archive_api_key" {
  type        = string
  description = "Optional. The API key to use to configure log analysis archiving with Cloud Object Storage. If no value is passed, the API key value that was passed in the `ibmcloud_api_key` variable is used."
  sensitive   = true
  default     = null
}

variable "enable_platform_logs" {
  type        = bool
  description = "When set to `true`, the IBM Cloud Logging instance collects the platform log files."
  default     = true
}
##############################################################################
# Activity Tracker Event Routing Variables
##############################################################################

variable "enable_at_event_routing_to_cos_bucket" {
  type        = bool
  description = "Set to true to enable activity tracker event routing to the Cloud Object Storage (COS) bucket."
  default     = true
}

variable "enable_at_event_routing_to_log_analysis" {
  type        = bool
  description = "Set to true to enable activity tracker event routing to the provisioned IBM Cloud Logging instance."
  default     = false
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

variable "cloud_monitoring_service_endpoints" {
  description = "The type of service endpoint to set for the IBM Cloud Monitoring instance."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.cloud_monitoring_service_endpoints)
    error_message = "The specified service endpoint is not valid. Specify a valid service endpoint to set for the IBM Cloud Monitoring instance."
  }
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
  description = "The type of endpoint to use to communicate with the key management service (KMS). Specify one of the following values for the endpoint type: `public` or `private` (default)."
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
