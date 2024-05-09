variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "Optional. The prefix to append to the resources created by this solution."
  default     = null
}

##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster that you want to deploy the agents in."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "Specify one of the following values to indicate which type of endpoint to use to access the cluster configuration: `default`, `private`, `vpe`, or `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "private"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "The specified endpoint type is not valid. Specify one of the following types of endpoints: `default`, `private`, `vpe`, or `link`."
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

##############################################################################
# Log Analysis variables
##############################################################################

variable "log_analysis_enabled" {
  type        = bool
  description = "Whether to deploy the IBM Cloud logging agent."
  default     = true
}


variable "log_analysis_agent_tags" {
  type        = list(string)
  description = "The list of tags to associate with all log records collected by the agent so that you can quickly identify the agent’s data in the logging UI. To add the cluster name as a tag, use the `log_analysis_add_cluster_name` variable."
  default     = []
  nullable    = false
}

variable "log_analysis_add_cluster_name" {
  type        = bool
  description = "When set to `true`, this variable configures the IBM Log Analysis agent to attach a tag that contains the cluster name to all log messages."
  default     = true
}

variable "log_analysis_ingestion_key" {
  type        = string
  description = "The ingestion key that is used by the IBM Cloud logging agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "log_analysis_secret_name" {
  type        = string
  description = "The name of the secret that will store the ingestion key. If a prefix input variable is passed, the secret name is prefixed to the value in the `<prefix>-value` format."
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_instance_region" {
  type        = string
  description = "The name of the region where the IBM Log Analysis instance is created. This name is used to construct the ingestion endpoint."
  default     = null
}

variable "log_analysis_endpoint_type" {
  type        = string
  description = "Specify the IBM Log Analysis instance endpoint type (`public` or `private`) to use to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified `endpoint_type` can be `private` or `public` only."
    condition     = contains(["private", "public"], var.log_analysis_endpoint_type)
  }
}

variable "log_analysis_agent_custom_line_inclusion" {
  description = "The custom configuration of the IBM Log Analysis agent for the `LOGDNA_K8S_METADATA_LINE_INCLUSION` line inclusion setting. For more information about this setting, see [Configuration for Kubernetes Metadata Filtering](https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering)."
  type        = string
  default     = null # "namespace:default"
}

variable "log_analysis_agent_custom_line_exclusion" {
  description = "The custom configuration of the IBM Log Analysis agent for the `LOGDNA_K8S_METADATA_LINE_INCLUSION` line exclusion setting. For more information about this setting, see [Configuration for Kubernetes Metadata Filtering](https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering)."
  type        = string
  default     = null # "label.app.kubernetes.io/name:sample-app\\, annotation.user:sample-user"
}

variable "log_analysis_agent_name" {
  description = "The name of the IBM Log Analysis agent that is used to name the Kubernetes and Helm resources on the cluster. If a prefix input variable is passed, the name of the IBM Log Analysis agent is prefixed to the value in the `<prefix>-value` format."
  type        = string
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_agent_namespace" {
  type        = string
  description = "The namespace to deploy the IBM Log Analysis agent in. The default value of the namespace is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "log_analysis_agent_tolerations" {
  description = "The list of tolerations to apply to the IBM Log Analysis agent. Because the default value is the `Exists` operator, this variable will match any taint on any node. For more information about tolerations and taints, see [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
  }]
}

##############################################################################
# Cloud Monitoring variables
##############################################################################

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "When set to `true`, this variable deploys the IBM Cloud Monitoring agent."
  default     = true
}

variable "cloud_monitoring_access_key" {
  type        = string
  description = "The access key that is used by the IBM Cloud Monitoring agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "cloud_monitoring_secret_name" {
  type        = string
  description = "The name of the secret that will store the access key. If a prefix input variable is passed, the secret name is prefixed to the value in the `<prefix>-value` format."
  default     = "sysdig-agent"
  nullable    = false
}

variable "cloud_monitoring_instance_region" {
  type        = string
  description = "The name of the region where the IBM Cloud Monitoring instance is created. This name is used to construct the ingestion endpoint."
  default     = null
}

variable "cloud_monitoring_endpoint_type" {
  type        = string
  description = "Specify the IBM Cloud Monitoring instance endpoint type (`public` or `private`) to use to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified `endpoint_type` can be `private` or `public` only."
    condition     = contains(["private", "public"], var.cloud_monitoring_endpoint_type)
  }
}

variable "cloud_monitoring_metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter on custom metrics, specify the IBM Cloud Monitoring metrics to include or exclude. For more information about customizing the monitoring agent configuration, see [Including and excluding metrics](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics)."
  default     = [] # [{ type = "exclude", name = "metricA.*" }, { type = "include", name = "metricB.*" }]
  validation {
    condition     = length(var.cloud_monitoring_metrics_filter) == 0 || can(regex("^(include|exclude)$", var.cloud_monitoring_metrics_filter[0].type))
    error_message = "The specified `type` for the `cloud_monitoring_metrics_filter` is not valid. Specify either `include` or `exclude`. If the value for `type` is not specified, no metrics are included or excluded."
  }
}

variable "cloud_monitoring_agent_tags" {
  type        = list(string)
  description = "A list of the tags to associate with the metrics that the IBM Cloud Monitoring agent collects. To add the cluster name as a tag, use the `cloud_monitoring_add_cluster_name` variable."
  default     = []
  nullable    = false
}

variable "cloud_monitoring_add_cluster_name" {
  type        = bool
  description = "When set to `true`, this variable configures the IBM Cloud Monitoring agent to attach a tag that contains the cluster name to all log messages."
  default     = true
}

variable "cloud_monitoring_agent_name" {
  description = "The name of the IBM Cloud Monitoring agent that is used to name the Kubernetes and Helm resources on the cluster. If a prefix input variable is passed, the name of the IBM Cloud Monitoring agent is prefixed to the value in the `<prefix>-value` format."
  type        = string
  default     = "sysdig-agent"
}

variable "cloud_monitoring_agent_namespace" {
  type        = string
  description = "The namespace to deploy the IBM Cloud Monitoring agent in. The default value of the namespace is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "cloud_monitoring_agent_tolerations" {
  description = " The list of tolerations to apply to the IBM Cloud Monitoring agent. The default value specifies that this variable will match any taint on any node except the master node. For more information about tolerations and taints, see [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
    },
    {
      operator : "Exists"
      effect : "NoSchedule"
      key : "node-role.kubernetes.io/master"
  }]
}
