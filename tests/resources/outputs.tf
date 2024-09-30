##############################################################################
# Outputs
##############################################################################

output "prefix" {
  value       = module.landing_zone.prefix
  description = "prefix"
}

output "region" {
  value       = var.region
  description = "Region where SLZ ROKS Cluster is deployed."
}

output "cluster_data" {
  value       = module.landing_zone.cluster_data
  description = "Details of OCP cluster."
}

output "workload_cluster_id" {
  value       = module.landing_zone.workload_cluster_id
  description = "ID of the workload cluster."
}

output "workload_cluster_crn" {
  value       = local.cluster_crn
  description = "CRN of the workload cluster."
}

output "cluster_resource_group_id" {
  value       = local.cluster_resource_group_id
  description = "Resource group ID of the workload cluster."
}

output "log_analysis_name" {
  value       = module.observability_instances.log_analysis_name
  description = "The name of the provisioned Log Analysis instance."
}

output "cloud_monitoring_name" {
  value       = module.observability_instances.cloud_monitoring_name
  description = "The name of the provisioned IBM Cloud Monitoring instance."
}

output "log_analysis_ingestion_key" {
  value       = module.observability_instances.log_analysis_ingestion_key
  description = "The ingestion key of the provisioned Log Analysis instance."
  sensitive   = true
}

output "cloud_monitoring_access_key" {
  value       = module.observability_instances.cloud_monitoring_access_key
  description = "The access key of the provisioned IBM Cloud Monitoring instance."
  sensitive   = true
}

output "trusted_profile_id" {
  value       = module.trusted_profile.trusted_profile.id
  description = "The ID of the trusted profile."
}

output "cloud_logs_ingress_private_endpoint" {
  value       = module.observability_instances.cloud_logs_ingress_private_endpoint
  description = "The private ingress endpoint of the provisioned Cloud Logs instance."
}
