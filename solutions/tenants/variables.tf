variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "tenant_configuration" {

  description = "List of tenants to be created for log routing"
  type = list(object({
    new_tenant_region = string
    new_tenant_name   = string
    target_name       = string
    log_sink_crn      = string
  }))

  default = [
    {
      new_tenant_region = "eu-de"
      new_tenant_name   = "vipin-tenant"
      target_name       = "test-target"
      log_sink_crn      = "crn:v1:bluemix:public:logs:us-south:a/abac0df06b644a9cabc6e44f55b3880e:f810f943-9eed-40c0-8265-9fc4790925c1::"
    }
  ]
}
