##############################################################################
# Observability Agents
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null
}

module "observability_agents" {
  source                       = "terraform-ibm-modules/observability-agents/ibm"
  version                      = "1.28.1"
  cluster_id                   = var.cluster_id
  cluster_resource_group_id    = var.cluster_resource_group_id
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
  # Log Analysis Agent
  log_analysis_enabled           = var.log_analysis_enabled
  log_analysis_agent_name        = var.prefix != null ? "${var.prefix}-${var.log_analysis_agent_name}" : var.log_analysis_agent_name
  log_analysis_agent_namespace   = var.log_analysis_agent_namespace
  log_analysis_instance_region   = var.log_analysis_instance_region
  log_analysis_ingestion_key     = var.log_analysis_ingestion_key
  log_analysis_secret_name       = var.prefix != null ? "${var.prefix}-${var.log_analysis_secret_name}" : var.log_analysis_secret_name
  log_analysis_agent_tolerations = var.log_analysis_agent_tolerations
  log_analysis_agent_tags        = var.log_analysis_agent_tags
  log_analysis_endpoint_type     = var.log_analysis_endpoint_type
  log_analysis_add_cluster_name  = var.log_analysis_add_cluster_name
  # Log Analysis agent custom settings to setup Kubernetes metadata logs filtering by setting
  # LOGDNA_K8S_METADATA_LINE_INCLUSION and LOGDNA_K8S_METADATA_LINE_EXCLUSION in the agent daemonset definition
  # Ref https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering
  log_analysis_agent_custom_line_exclusion = var.log_analysis_agent_custom_line_inclusion
  log_analysis_agent_custom_line_inclusion = var.log_analysis_agent_custom_line_exclusion
  # Cloud Monitoring (Sysdig) Agent
  cloud_monitoring_enabled           = var.cloud_monitoring_enabled
  cloud_monitoring_agent_name        = var.prefix != null ? "${var.prefix}-${var.cloud_monitoring_agent_name}" : var.cloud_monitoring_agent_name
  cloud_monitoring_agent_namespace   = var.cloud_monitoring_agent_namespace
  cloud_monitoring_endpoint_type     = var.cloud_monitoring_endpoint_type
  cloud_monitoring_access_key        = var.cloud_monitoring_access_key
  cloud_monitoring_secret_name       = var.prefix != null ? "${var.prefix}-${var.cloud_monitoring_secret_name}" : var.cloud_monitoring_secret_name
  cloud_monitoring_metrics_filter    = var.cloud_monitoring_metrics_filter
  cloud_monitoring_agent_tags        = var.cloud_monitoring_agent_tags
  cloud_monitoring_instance_region   = var.cloud_monitoring_instance_region
  cloud_monitoring_agent_tolerations = var.cloud_monitoring_agent_tolerations
  cloud_monitoring_add_cluster_name  = var.cloud_monitoring_add_cluster_name
}
