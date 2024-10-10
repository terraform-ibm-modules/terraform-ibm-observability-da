##############################################################################
# Outputs
##############################################################################


output "resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "The name of the Resource Group the instances are provisioned in."
}

output "resource_group_id" {
  value       = module.resource_group.resource_group_id
  description = "The ID of the Resource Group the instances are provisioned in."
}

## Cloud logs
output "cloud_logs_crn" {
  value       = var.cloud_logs_provision ? module.observability_instance.cloud_logs_crn : null
  description = "The id of the provisioned Cloud Logs instance."
}

output "cloud_logs_guid" {
  value       = var.cloud_logs_provision ? module.observability_instance.cloud_logs_guid : null
  description = "The guid of the provisioned Cloud Logs instance."
}

output "cloud_logs_name" {
  value       = var.cloud_logs_provision ? module.observability_instance.cloud_logs_name : null
  description = "The name of the provisioned Cloud Logs instance."
}

## Log analysis
output "log_analysis_name" {
  value       = var.log_analysis_provision ? module.observability_instance.log_analysis_name : null
  description = "The name of the provisioned Log Analysis instance."
}

output "log_analysis_crn" {
  value       = var.log_analysis_provision ? module.observability_instance.log_analysis_crn : null
  description = "The id of the provisioned Log Analysis instance."
}

output "log_analysis_guid" {
  value       = var.log_analysis_provision ? module.observability_instance.log_analysis_guid : null
  description = "vaThe guid of the provisioned Log Analysis instance."
}

output "log_analysis_ingestion_key" {
  value       = var.log_analysis_provision ? module.observability_instance.log_analysis_ingestion_key : null
  description = "Log Analysis ingest key for agents to use"
  sensitive   = true
}

## Cloud Monitoring
output "cloud_monitoring_name" {
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_name : null
  description = "The name of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_crn" {
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_crn : (var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : null)
  description = "The id of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_guid : local.existing_cloud_monitoring_guid
  description = "The guid of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_access_key" {
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_access_key : null
  description = "IBM cloud monitoring access key for agents to use"
  sensitive   = true
}

## COS Instance
output "cos_instance_id" {
  description = "COS instance id"
  value       = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_id : null : null
}

output "cos_instance_guid" {
  description = "COS instance guid"
  value       = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_guid : null : null
}

output "cos_instance_name" {
  description = "COS instance name"
  value       = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_name : null : null
}

output "cos_instance_crn" {
  description = "COS instance crn"
  value       = var.existing_cos_instance_crn == null ? length(module.cos_instance) != 0 ? module.cos_instance[0].cos_instance_crn : null : null
}

## COS Buckets
output "log_archive_cos_bucket_name" {
  value       = var.existing_log_archive_cos_bucket_name == null ? var.log_analysis_provision ? module.cos_bucket[0].buckets[local.log_archive_cos_bucket_name].bucket_name : null : var.existing_log_archive_cos_bucket_name
  description = "The name of log archive COS bucket"
}

output "at_cos_target_bucket_name" {
  value       = var.existing_at_cos_target_bucket_name == null ? var.enable_at_event_routing_to_cos_bucket ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].bucket_name : null : var.existing_at_cos_target_bucket_name
  description = "The name of the AT target COS bucket"
}

output "cloud_log_data_bucket_name" {
  value       = var.existing_cloud_logs_data_bucket_crn == null && var.cloud_logs_provision ? module.cos_bucket[0].buckets[local.cloud_log_data_bucket].bucket_name : local.existing_cloud_log_data_bucket_name
  description = "The name of the Cloud logs data COS bucket"
}

output "cloud_log_metrics_bucket_name" {
  value       = var.existing_cloud_logs_metrics_bucket_crn == null && var.cloud_logs_provision ? module.cos_bucket[0].buckets[local.cloud_log_metrics_bucket].bucket_name : local.existing_cloud_log_metrics_bucket_name
  description = "The name of the Cloud logs metrics COS bucket"
}

## Activity Tracker
output "at_targets" {
  value       = module.observability_instance.activity_tracker_targets
  description = "The map of created activity_tracker targets"
}

output "at_routes" {
  value       = module.observability_instance.activity_tracker_routes
  description = "The map of created activity_tracker routes"
}

## KMS
output "kms_key_rings" {
  description = "IDs of new KMS Key Rings created"
  value       = length(module.kms) > 0 ? module.kms[0].key_rings : null
}

output "kms_keys" {
  description = "IDs of new KMS Keys created"
  value       = length(module.kms) > 0 ? module.kms[0].keys : null
}
