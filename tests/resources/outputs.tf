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

output "log_analysis_name" {
  value       = module.observability_instances.log_analysis_name
  description = "The name of the provisioned Log Analysis instance."
}

output "cloud_monitoring_name" {
  value       = module.observability_instances.cloud_monitoring_name
  description = "The name of the provisioned IBM cloud monitoring instance."
}
