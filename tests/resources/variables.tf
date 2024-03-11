variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region to provision all resources created by this example."
  default     = "us-south"
}

variable "prefix" {
  type        = string
  description = "Prefix to append to all resources created by this example."
  default     = "agents-da"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources."
  default     = ["obs-agent-ocp"]
}

# variable "cluster_config_endpoint_type" {
#   type        = string
#   description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'."
#   default     = "private"
# }
