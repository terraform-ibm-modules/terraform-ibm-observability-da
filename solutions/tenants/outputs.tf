##############################################################################
# Outputs
##############################################################################


##############################################################################

output "tenants_details" {

  value = {
    for idx, tenant in var.tenant_configuration : idx => {
      "name" : var.tenant_configuration[idx].tenant_name,
      "id" : ibm_logs_router_tenant.logs_router_tenant_instances[idx].id,
      "crn" : ibm_logs_router_tenant.logs_router_tenant_instances[idx].crn
    }
  }
  description = "Details of tenant created through this configuration"
}
