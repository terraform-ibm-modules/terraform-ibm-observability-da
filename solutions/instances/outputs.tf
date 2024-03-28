##############################################################################
# Outputs
##############################################################################

output "log_analysis_name" {
  value       = module.observability_instance.log_analysis_name
  description = "The name of the provisioned Log Analysis instance."
}

output "log_analysis_crn" {
  value       = module.observability_instance.log_analysis_crn
  description = "The id of the provisioned Log Analysis instance."
}

output "log_analysis_guid" {
  value       = module.observability_instance.log_analysis_guid
  description = "vaThe guid of the provisioned Log Analysis instance."
}

output "log_analysis_ingestion_key" {
  value       = module.observability_instance.log_analysis_ingestion_key
  description = "Log Analysis ingest key for agents to use"
  sensitive   = true
}

output "cloud_monitoring_name" {
  value       = module.observability_instance.cloud_monitoring_name
  description = "The name of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_crn" {
  value       = module.observability_instance.cloud_monitoring_crn
  description = "The id of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = module.observability_instance.cloud_monitoring_guid
  description = "The guid of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_access_key" {
  value       = module.observability_instance.cloud_monitoring_access_key
  description = "IBM cloud monitoring access key for agents to use"
  sensitive   = true
}

output "log_archive_cos_bucket_name" {
  value       = var.existing_log_archive_cos_bucket_name == null ? module.cos_bucket[0].buckets[var.log_archive_cos_bucket_name].bucket_name : var.existing_log_archive_cos_bucket_name
  description = "The name of log archive COS bucket"
}

output "at_cos_target_bucket_name" {
  value       = var.existing_at_cos_target_bucket_name == null ? module.cos_bucket[0].buckets[var.at_cos_target_bucket_name].bucket_name : var.existing_at_cos_target_bucket_name
  description = "The name of the at cos target bucket"
}

output "at_cos_targets" {
  value       = module.observability_instance.activity_tracker_targets
  description = "The map of created targets"
}

output "at_routes" {
  value       = module.observability_instance.activity_tracker_routes
  description = "The map of created routes"
}
