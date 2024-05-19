########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API Key to use for IBM Cloud."
  sensitive   = true
}

variable "use_existing_resource_group" {
  type        = bool
  description = "Whether to use an existing resource group."
  default     = false
}

variable "resource_group_name" {
  type        = string
  description = "The name of a new or an existing resource group in which to provision resources to. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}

variable "region" {
  description = "Region where observability resources will be created"
  type        = string
  default     = "us-south"

  validation {
    condition     = contains(["us-south", "us-east", "jp-osa", "jp-tok", "eu-de", "eu-es", "eu-gb", "au-syd"], var.region)
    error_message = "The specified region is not a valid selection!"
  }
}

variable "prefix" {
  type        = string
  description = "(Optional) Prefix to append to all resources created by this solution."
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
  description = "The name of the IBM Cloud Logging instance to create. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
  default     = "log-analysis"
}

variable "log_analysis_plan" {
  type        = string
  description = "The IBM Cloud Logging plan to provision. Available: lite, 7-day, 14-day, 30-day, hipaa-30-day"
  default     = "7-day"

  validation {
    condition     = can(regex("^lite$|^7-day$|^14-day$|^30-day$|^hipaa-30-day$", var.log_analysis_plan))
    error_message = "The log_analysis_plan value must be one of the following: lite, 7-day, 14-day, 30-day, hipaa-30-day."
  }
}

variable "log_analysis_service_endpoints" {
  description = "The type of the service endpoint that will be set for the Log Analysis instance."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.log_analysis_service_endpoints)
    error_message = "The specified service_endpoints is not a valid selection"
  }
}

variable "log_analysis_tags" {
  type        = list(string)
  description = "Tags associated with the IBM Cloud Logging instance (Optional, array of strings)."
  default     = []
}

variable "enable_log_archive" {
  type        = bool
  description = "Enable archive on log analysis instance"
  default     = true
}

variable "log_archive_api_key" {
  type        = string
  description = "(Optional) The API key to use to configure log analysis archiving with COS. If no value passed, the API key value passed in the 'ibmcloud_api_key' variable will be used."
  sensitive   = true
  default     = null
}

variable "enable_platform_logs" {
  type        = bool
  description = "Receive platform logs in the provisioned IBM Cloud Logging instance."
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
  description = "Set it to true to provision an IBM cloud monitoring instance"
  type        = bool
  default     = true
}

variable "cloud_monitoring_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Monitoring instance to create. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
  default     = "cloud-monitoring"
}

variable "cloud_monitoring_plan" {
  type        = string
  description = "The IBM Cloud Monitoring plan to provision. Available: lite, graduated-tier"
  default     = "graduated-tier"

  validation {
    condition     = can(regex("^lite$|^graduated-tier$", var.cloud_monitoring_plan))
    error_message = "The cloud_monitoring_plan value must be one of the following: lite, graduated-tier."
  }
}

variable "cloud_monitoring_tags" {
  type        = list(string)
  description = "Tags associated with the IBM Cloud Monitoring instance (Optional, array of strings)."
  default     = []
}

variable "cloud_monitoring_service_endpoints" {
  description = "The type of the service endpoint that will be set for the IBM cloud monitoring instance."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "public-and-private"], var.cloud_monitoring_service_endpoints)
    error_message = "The specified service_endpoints is not a valid selection"
  }
}

variable "enable_platform_metrics" {
  type        = bool
  description = "Receive platform metrics in the provisioned IBM Cloud Monitoring instance."
  default     = true
}

########################################################################################################################
# AT targets and routes
########################################################################################################################

variable "configure_cos_target_and_route_for_atracker_events" {
  description = "Set it to true if COS targets and routes needs to be configured for activity tracker event routing"
  type        = bool
  default     = true
}

########################################################################################################################
# COS variables
########################################################################################################################

variable "add_bucket_name_suffix" {
  type        = bool
  description = "Add random generated suffix (4 characters long) to the newly provisioned COS buckets name. Only used if not passing existing bucket. Set to false if you want full control over bucket naming using the 'log_archive_cos_bucket_name' and 'at_cos_target_bucket_name' variables."
  default     = true
}

variable "cos_region" {
  type        = string
  default     = null
  description = "The Cloud Object Storage region. If no value is provided, it defaults to the value specified in the 'region' input variable."
}

variable "cos_instance_name" {
  type        = string
  default     = "observability-cos"
  description = "The name to use when creating the Cloud Object Storage instance. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}

variable "cos_instance_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to Cloud Object Storage instance. Only used if not supplying an existing instance."
  default     = []
}

variable "cos_instance_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Cloud Object Storage instance. Only used if not supplying an existing instance."
  default     = []
}

variable "log_archive_cos_bucket_name" {
  type        = string
  default     = "log-archive-cos-bucket"
  description = "The name to use when creating the Cloud Object Storage bucket for storing log archives (NOTE: bucket names are globally unique). If 'add_bucket_name_suffix' is set to true, a random 4 characters will be added to this name to help ensure bucket name is globally unique. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}

variable "at_cos_target_bucket_name" {
  type        = string
  default     = "at-events-cos-bucket"
  description = "The name to use when creating the Cloud Object Storage bucket for cos target (NOTE: bucket names are globally unique). If 'add_bucket_name_suffix' is set to true, a random 4 characters will be added to this name to help ensure bucket name is globally unique. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}

variable "archive_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "Optional list of access tags to be added to the log archive COS bucket."
}

variable "at_cos_bucket_access_tags" {
  type        = list(string)
  default     = []
  description = "Optional list of access tags to be added to the activity tracking event routing COS bucket."
}

variable "log_archive_cos_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned COS bucket. Allowed values are: 'standard', 'vault', 'cold', 'smart' (default value), 'onerate_active'"
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.log_archive_cos_bucket_class)
    error_message = "Allowed values for cos_bucket_class are \"standard\", \"vault\",\"cold\", \"smart\", or \"onerate_active\"."
  }
}

variable "at_cos_target_bucket_class" {
  type        = string
  default     = "smart"
  description = "The storage class of the newly provisioned COS bucket. Allowed values are: 'standard', 'vault', 'cold', 'smart' (default value), 'onerate_active'"
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.at_cos_target_bucket_class)
    error_message = "Allowed values for cos_bucket_class are \"standard\", \"vault\",\"cold\", \"smart\", or \"onerate_active\"."
  }
}

variable "existing_cos_instance_crn" {
  type        = string
  nullable    = true
  default     = null
  description = "The CRN of an existing Cloud Object Storage instance. If not supplied, a new instance will be created."
}

variable "existing_log_archive_cos_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket inside the existing Cloud Object Storage instance to use for storing log archive. If not supplied, a new bucket will be created."
}

variable "existing_at_cos_target_bucket_name" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing bucket inside the existing Cloud Object Storage instance to use for activity tracker event routing. If not supplied, a new bucket will be created."
}

variable "existing_log_archive_cos_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing cos bucket endpoint to use for storing log archive. If not supplied, the endpoint of the new bucket will be used."
}

variable "existing_at_cos_target_bucket_endpoint" {
  type        = string
  nullable    = true
  default     = null
  description = "The name of an existing cos bucket endpoint to use for setting up activity tracker event routing. If not supplied, the endpoint of the new bucket will be used."
}

variable "skip_cos_kms_auth_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits the COS instance created to read the encryption key from the KMS instance. WARNING: An authorization policy must exist before an encrypted bucket can be created"
  default     = false
}

variable "management_endpoint_type_for_bucket" {
  description = "The type of endpoint for the IBM terraform provider to use to manage COS buckets. (`public`, `private` or `direct`). Ensure to enable virtual routing and forwarding (VRF) in your account if using `private`, and that the terraform runtime has access to the the IBM Cloud private network."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_bucket)
    error_message = "The specified management_endpoint_type_for_bucket is not a valid selection!"
  }
}

########################################################################################################################
# KMS variables
########################################################################################################################

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of the KMS instance used for the COS bucket root Key. Only required if not supplying an existing KMS root key. Not required if existing bucket details are passed as an input."
}

variable "existing_cos_kms_key_crn" {
  type        = string
  default     = null
  description = "(OPTIONAL) The CRN of an existing KMS key to be used to encrypt the Cloud Object Storage buckets created by this solution. If no value is passed, a value must be passed for either the existing_kms_instance_crn input variable if you want to create a new key ring and key, or the existing_log_archive_cos_bucket_name and existing_at_cos_target_bucket_name input variables if you want to use existing buckets."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to be used for commincating with the KMS instance. Allowed values are: 'public' or 'private' (default)"
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "The kms_endpoint_type value must be 'public' or 'private'."
  }
}

variable "cos_key_ring_name" {
  type        = string
  default     = "observability-cos-key-ring"
  description = "The name to give the Key Ring which will be created for the COS bucket Key. Will be used by both log archive bucket and AT COS bucket. Not used if supplying an existing Key. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}

variable "cos_key_name" {
  type        = string
  default     = "observability-cos-key"
  description = "The name to give the Key which will be created for the COS bucket. Will be used by both log archive bucket and AT COS bucket. Not used if supplying an existing Key. If prefix input variable is passed then it will get prefixed infront of the value in the format of '<prefix>-value'"
}
