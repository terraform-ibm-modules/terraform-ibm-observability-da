##############################################################################
# Outputs
##############################################################################

output "prefix" {
  value       = var.prefix
  description = "prefix"
}

output "region" {
  value       = var.region
  description = "Region where OCP Cluster is deployed."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "ID of the cluster."
}

output "resource_group_id" {
  value       = module.resource_group.resource_group_id
  description = "Resource group ID"
}

output "cloud_monitoring_name" {
  value       = module.observability_instances.cloud_monitoring_name
  description = "The name of the provisioned IBM Cloud Monitoring instance."
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

output "cloud_logs_instance_name" {
  value       = module.observability_instances.cloud_logs_name
  description = "The name of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_ingress_private_endpoint" {
  value       = module.observability_instances.cloud_logs_ingress_private_endpoint
  description = "The private ingress endpoint of the provisioned Cloud Logs instance."
}
