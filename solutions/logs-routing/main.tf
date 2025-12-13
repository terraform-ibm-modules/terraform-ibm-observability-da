module "icl_crn_parser" {
  for_each = { for idx, tenant in var.tenant_configuration : idx => tenant }
  source   = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version  = "1.3.5"
  crn      = each.value.log_sink_crn
}

data "ibm_resource_instance" "icl_instance" {
  for_each   = { for idx, tenant in var.tenant_configuration : idx => tenant }
  identifier = module.icl_crn_parser[each.key].service_instance
}

resource "ibm_logs_router_tenant" "logs_router_tenant_instances" {
  for_each = { for idx, tenant in var.tenant_configuration : idx => tenant }
  name     = each.value.tenant_name
  region   = each.value.tenant_region
  targets {
    log_sink_crn = each.value.log_sink_crn
    name         = each.value.target_name
    parameters {
      host = data.ibm_resource_instance.icl_instance[each.key].extensions.external_ingress_private
      port = 443
    }
  }
}
