##############################################################################
# Observability Agents
##############################################################################

locals {
  prefix = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].id : data.ibm_container_cluster.cluster[0].id
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null
}

module "logs_agent" {
  count                                  = var.logs_agent_enabled ? 1 : 0
  source                                 = "terraform-ibm-modules/logs-agent/ibm"
  version                                = "1.0.4"
  cluster_id                             = var.cluster_id
  cluster_resource_group_id              = var.cluster_resource_group_id
  cluster_config_endpoint_type           = var.cluster_config_endpoint_type
  is_vpc_cluster                         = var.is_vpc_cluster
  wait_till                              = var.wait_till
  wait_till_timeout                      = var.wait_till_timeout
  logs_agent_chart                       = var.logs_agent_chart
  logs_agent_chart_location              = var.logs_agent_chart_location
  logs_agent_chart_version               = var.logs_agent_chart_version
  logs_agent_image_version               = var.logs_agent_image_version
  logs_agent_name                        = "${local.prefix}${var.logs_agent_name}"
  logs_agent_namespace                   = var.logs_agent_namespace
  logs_agent_trusted_profile_id          = var.logs_agent_trusted_profile
  logs_agent_iam_api_key                 = var.logs_agent_iam_api_key
  logs_agent_tolerations                 = var.logs_agent_tolerations
  logs_agent_resources                   = var.logs_agent_resources
  logs_agent_additional_log_source_paths = var.logs_agent_additional_log_source_paths
  logs_agent_exclude_log_source_paths    = var.logs_agent_exclude_log_source_paths
  logs_agent_selected_log_source_paths   = var.logs_agent_selected_log_source_paths
  logs_agent_log_source_namespaces       = var.logs_agent_log_source_namespaces
  logs_agent_iam_mode                    = var.logs_agent_iam_mode
  logs_agent_iam_environment             = var.logs_agent_iam_environment
  logs_agent_additional_metadata         = var.logs_agent_additional_metadata
  logs_agent_enable_scc                  = var.logs_agent_enable_scc
  cloud_logs_ingress_endpoint            = var.cloud_logs_ingress_endpoint
  cloud_logs_ingress_port                = var.cloud_logs_ingress_port
}

module "monitoring_agent" {
  count                                   = var.cloud_monitoring_enabled ? 1 : 0
  source                                  = "terraform-ibm-modules/monitoring-agent/ibm"
  version                                 = "1.0.14"
  cluster_id                              = var.cluster_id
  cluster_resource_group_id               = var.cluster_resource_group_id
  cluster_config_endpoint_type            = var.cluster_config_endpoint_type
  is_vpc_cluster                          = var.is_vpc_cluster
  wait_till_timeout                       = var.wait_till_timeout
  wait_till                               = var.wait_till
  access_key                              = var.cloud_monitoring_access_key
  cloud_monitoring_instance_region        = var.cloud_monitoring_instance_region
  cloud_monitoring_instance_endpoint_type = var.cloud_monitoring_endpoint_type
  metrics_filter                          = var.cloud_monitoring_metrics_filter
  container_filter                        = var.cloud_monitoring_container_filter
  name                                    = "${local.prefix}${var.cloud_monitoring_agent_name}"
  namespace                               = var.cloud_monitoring_agent_namespace
  tolerations                             = var.cloud_monitoring_agent_tolerations
  chart                                   = var.cloud_monitoring_chart
  chart_location                          = var.cloud_monitoring_chart_location
  chart_version                           = var.cloud_monitoring_chart_version
  image_registry                          = var.cloud_monitoring_image_registry
  image_tag_digest                        = var.cloud_monitoring_image_tag_digest
}
