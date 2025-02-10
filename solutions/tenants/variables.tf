variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "tenant_configuration" {

  description = "List of tenants to be created for log routing"
  type = list(object({
    create_new_tenant   = optional(bool)
    existing_tenant_crn = optional(string) # validate this has a value if create_new_tenant is false. Parse the region from the CRN
    new_tenant_region   = optional(string) # validate this has a value if create_new_tenant is true
    new_tenant_name     = optional(string) # validate this has a value if create_new_tenant is true
    target_name         = string
    log_sink_crn        = string
  }))

  default = []
  validation {
    condition = alltrue([for tenant in var.tenant_configuration :
      (tenant.create_new_tenant == false || tenant.create_new_tenant == null) ?
      (tenant.existing_tenant_crn != null) :
      (tenant.new_tenant_region != null && tenant.new_tenant_name != null && tenant.existing_tenant_crn == null)
    ])
    error_message = "If 'create_new_tenant' is false or not provided, 'existing_tenant_crn' must be provided. If 'create_new_tenant' is true, both 'new_tenant_region' and 'new_tenant_name' must be provided."
  }
}
