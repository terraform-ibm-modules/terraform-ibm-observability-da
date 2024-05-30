##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "prefix" {
  value       = var.prefix
  description = "Prefix"
}

output "cos_crn" {
  description = "COS CRN"
  value       = module.cos.cos_instance_crn
}

output "bucket_name" {
  description = "Bucket name"
  value       = module.cos.bucket_name
}

output "bucket_name_at" {
  description = "Activity Tracker Bucket name"
  value       = module.additional_cos_bucket.bucket_name
}

output "bucket_endpoint" {
  description = "Bucket name"
  value       = module.cos.s3_endpoint_public
}

output "bucket_endpoint_at" {
  description = "Activity Tracker Bucket name"
  value       = module.additional_cos_bucket.s3_endpoint_public
}
