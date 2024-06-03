##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "prefix" {
  description = "Prefix"
  value       = var.prefix
}

output "cos_crn" {
  description = "COS CRN"
  value       = module.cos.cos_instance_crn
}

output "bucket_name" {
  description = "Log Archive bucket name"
  value       = module.cos.bucket_name
}

output "bucket_name_at" {
  description = "Activity Tracker bucket name"
  value       = module.additional_cos_bucket.bucket_name
}

output "bucket_endpoint" {
  description = "Log Archive bucket endpoint"
  value       = module.cos.s3_endpoint_public
}

output "bucket_endpoint_at" {
  description = "Activity Tracker bucket endpoint"
  value       = module.additional_cos_bucket.s3_endpoint_public
}
