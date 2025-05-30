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
  value       = var.cloud_logs_provision ? module.cloud_logs[0].crn : null
  description = "The id of the provisioned Cloud Logs instance."
}

output "cloud_logs_guid" {
  value       = var.cloud_logs_provision ? module.cloud_logs[0].guid : null
  description = "The guid of the provisioned Cloud Logs instance."
}

output "cloud_logs_name" {
  value       = var.cloud_logs_provision ? module.cloud_logs[0].name : null
  description = "The name of the provisioned Cloud Logs instance."
}

output "cloud_logs_resource_group_id" {
  value       = var.cloud_logs_provision ? module.cloud_logs[0].resource_group_id : null
  description = "The resource group where Cloud Logs instance resides."
}

output "cloud_logs_ingress_endpoint" {
  value       = var.cloud_logs_provision ? module.cloud_logs[0].ingress_endpoint : null
  description = "The public ingress endpoint of the provisioned Cloud Logs instance."
}

output "cloud_logs_ingress_private_endpoint" {
  value       = var.cloud_logs_provision ? module.cloud_logs[0].ingress_private_endpoint : null
  description = "The private ingress endpoint of the provisioned Cloud Logs instance."
}

## Cloud logs policies
output "logs_policies_details" {
  value       = length(var.cloud_logs_policies) > 0 ? module.cloud_logs[0].logs_policies_details : null
  description = "The details of the Cloud logs policies created."
}

## Cloud Monitoring
output "cloud_monitoring_name" {
  value       = var.cloud_monitoring_provision ? module.cloud_monitoring[0].name : (var.existing_cloud_monitoring_crn != null ? module.cloud_monitoring_crn_parser[0].service_name : null)
  description = "The name of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_crn" {
  value       = var.cloud_monitoring_provision ? module.cloud_monitoring[0].crn : (var.existing_cloud_monitoring_crn != null ? var.existing_cloud_monitoring_crn : null)
  description = "The id of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_guid" {
  value       = var.cloud_monitoring_provision ? module.cloud_monitoring[0].guid : var.existing_cloud_monitoring_crn != null ? module.cloud_monitoring_crn_parser[0].service_instance : null
  description = "The guid of the provisioned IBM cloud monitoring instance."
}

output "cloud_monitoring_access_key" {
  value       = var.cloud_monitoring_provision ? module.cloud_monitoring[0].access_key : null
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
  value       = var.manage_log_archive_cos_bucket ? module.cos_bucket[0].buckets[local.log_archive_cos_bucket_name].bucket_name : null
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
  value       = module.activity_tracker.activity_tracker_targets
  description = "The map of created activity_tracker targets"
}

output "at_routes" {
  value       = module.activity_tracker.activity_tracker_routes
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

## Metrics Routing

output "metrics_router_targets" {
  description = "The map of created metrics routing targets."
  value       = var.enable_metrics_routing_to_cloud_monitoring ? module.metrics_router.metrics_router_targets : null
}

output "metrics_router_routes" {
  description = "The map of created metrics routing routes."
  value       = var.enable_metrics_routing_to_cloud_monitoring ? module.metrics_router.metrics_router_routes : null
}
