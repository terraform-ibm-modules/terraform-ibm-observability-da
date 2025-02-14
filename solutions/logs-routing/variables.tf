variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "public"
  # NOTE. Provider visibility is set to public because of provider issue. (https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5977)

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "tenant_configuration" {

  description = "List of tenants to be created for log routing.[Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/tree/main/solutions/logs-routing/DA-types.md)."
  type = list(object({
    tenant_region = string
    tenant_name   = string
    target_name   = string
    log_sink_crn  = string
  }))

}
