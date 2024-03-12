##############################################################################
# Outputs
##############################################################################

output "log_analysis_crn" {
  value       = module.observability_instance.log_analysis_crn
  description = "The id of the provisioned Log Analysis instance."
}

output "log_analysis_guid" {
  value       = module.observability_instance.log_analysis_guid
  description = "vaThe guid of the provisioned Log Analysis instance."
}

output "cloud_monitoring_crn" {
  value       = module.observability_instance.cloud_monitoring_crn
  description = "The id of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = module.observability_instance.cloud_monitoring_guid
  description = "The guid of the provisioned IBM cloud monitoring instance."
}

output "cos_bucket_details" {
  value       = module.cos[0].buckets
  sensitive   = true
  description = "The details of the COS buckets."
}
