##############################################################################
# Outputs
##############################################################################

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
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_crn : null
  description = "The id of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = var.cloud_monitoring_provision ? module.observability_instance.cloud_monitoring_guid : null
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
  value       = var.existing_cos_instance_crn == null ? module.cos_instance[0].cos_instance_id : null
}

output "cos_instance_guid" {
  description = "COS instance guid"
  value       = var.existing_cos_instance_crn == null ? module.cos_instance[0].cos_instance_guid : null
}

output "cos_instance_name" {
  description = "COS instance name"
  value       = var.existing_cos_instance_crn == null ? module.cos_instance[0].cos_instance_name : null
}

output "cos_instance_crn" {
  description = "COS instance crn"
  value       = var.existing_cos_instance_crn == null ? module.cos_instance[0].cos_instance_crn : null
}

## COS Buckets
output "log_archive_cos_bucket_name" {
  value       = var.existing_log_archive_cos_bucket_name == null ? module.cos_bucket[0].buckets[local.log_archive_cos_bucket_name].bucket_name : var.existing_log_archive_cos_bucket_name
  description = "The name of log archive COS bucket"
}

output "at_cos_target_bucket_name" {
  value       = var.existing_at_cos_target_bucket_name == null ? module.cos_bucket[0].buckets[local.at_cos_target_bucket_name].bucket_name : var.existing_at_cos_target_bucket_name
  description = "The name of the AT target COS bucket"
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
