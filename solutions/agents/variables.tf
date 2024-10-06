variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "The prefix for resources created by this solution."
  default     = null
}

##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agents in."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "Specify the type of endpoint to use to access the cluster configuration. Possible values: `default`, `private`, `vpe`, `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "private"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "The specified endpoint type is not valid. Specify one of the following types of endpoints: `default`, `private`, `vpe`, or `link`."
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the DA is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` or `Normal`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady",
      "Normal"
    ], var.wait_till)
  }
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Log Analysis variables
##############################################################################

variable "log_analysis_enabled" {
  type        = bool
  description = "DEPRECATED: Whether to deploy the IBM Cloud logging agent."
  default     = false
}


variable "log_analysis_agent_tags" {
  type        = list(string)
  description = "DEPRECATED: The list of tags to associate with all log records collected by the agent so that you can quickly identify the agent’s data in the logging UI. To add the cluster name as a tag, use the `log_analysis_add_cluster_name` variable."
  default     = []
  nullable    = false
}

variable "log_analysis_add_cluster_name" {
  type        = bool
  description = "DEPRECATED: Whether to attach the cluster name to log messages. Set to `true` to configure the IBM Log Analysis agent to tag all log messages with the name."
  default     = true
}

variable "log_analysis_ingestion_key" {
  type        = string
  description = "DEPRECATED: The ingestion key that is used by the IBM Cloud logging agent to communicate with the instance."
  sensitive   = true
  default     = null
}

variable "log_analysis_secret_name" {
  type        = string
  description = "DEPRECATED: The name of the secret that stores the ingestion key. If a prefix input variable is specified, the secret name is prefixed to the value in the `<prefix>-<name>` format."
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_instance_region" {
  type        = string
  description = "DEPRECATED: The name of the region where the IBM Log Analysis instance is created. The value is used in the ingestion endpoint in the format `api.<var-value>.logging.cloud.ibm.com`."
  default     = null
}

variable "log_analysis_endpoint_type" {
  type        = string
  description = "DEPRECATED: Specify the IBM Log Analysis instance endpoint type to use to construct the ingestion endpoint. Possible values: `public` or `private`."
  default     = "private"
  validation {
    error_message = "The specified `endpoint_type` can be `private` or `public` only."
    condition     = contains(["private", "public"], var.log_analysis_endpoint_type)
  }
}

variable "log_analysis_agent_custom_line_inclusion" {
  description = "DEPRECATED: The custom configuration of the IBM Log Analysis agent for the `LOGDNA_K8S_METADATA_LINE_INCLUSION` line inclusion setting. [Learn more](https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering)"
  type        = string
  default     = null # "namespace:default"
}

variable "log_analysis_agent_custom_line_exclusion" {
  description = "DEPRECATED: The custom configuration of the IBM Log Analysis agent for the `LOGDNA_K8S_METADATA_LINE_INCLUSION` line exclusion setting. [Learn more](https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering)"
  type        = string
  default     = null # "label.app.kubernetes.io/name:sample-app\\, annotation.user:sample-user"
}

variable "log_analysis_agent_name" {
  description = "DEPRECATED: The name of the IBM Log Analysis agent that is used to name the Kubernetes and Helm resources on the cluster. If a prefix input variable is passed, the name of the IBM Log Analysis agent is prefixed to the value in the `<prefix>-<name>` format."
  type        = string
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_agent_namespace" {
  type        = string
  description = "DEPRECATED: The namespace to deploy the IBM Log Analysis agent in. The default value of the namespace is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "log_analysis_agent_tolerations" {
  description = "DEPRECATED: The list of tolerations to apply to the IBM Log Analysis agent. Because the default value is the `Exists` operator, this variable will match any taint on any node. [Learn more](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)"
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
  description = "Whether to deploy the IBM Cloud Monitoring agent."
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
  description = "The name of the secret that will store the access key. If a prefix input variable is passed, the secret name is prefixed to the value in the `<prefix>-<name>` format."
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
  description = "To filter on custom metrics, specify the IBM Cloud Monitoring metrics to include or exclude. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics)"
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
  description = "Whether to attach a tag to log messages. Set to `true` to configure the IBM Cloud Monitoring agent to attach a tag that contains the cluster name to all log messages."
  default     = true
}

variable "cloud_monitoring_agent_name" {
  description = "The name of the IBM Cloud Monitoring agent that is used to name the Kubernetes and Helm resources on the cluster. If a prefix input variable is passed, the name of the IBM Cloud Monitoring agent is prefixed to the value in the `<prefix>-<name>` format."
  type        = string
  default     = "sysdig-agent"
}

variable "cloud_monitoring_agent_namespace" {
  type        = string
  description = "The namespace to deploy the IBM Cloud Monitoring agent in. Default value: `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "cloud_monitoring_agent_tolerations" {
  description = "The list of tolerations to apply to the IBM Cloud Monitoring agent. The default operator value `Exists` matches any taint on any node except the master node. [Learn more](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)"
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

##############################################################################
# Logs Agents variables
##############################################################################

variable "logs_agent_enabled" {
  type        = bool
  description = "Whether to deploy the Logs agent."
  default     = true
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_agent_trusted_profile" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role."
  default     = null
}

variable "logs_agent_iam_api_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`."
  sensitive   = true
  default     = null
}

variable "logs_agent_tolerations" {
  description = "List of tolerations to apply to Logs agent."
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

variable "logs_agent_additional_log_source_paths" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/logger-agent-ds-*.log`."
  default     = []
  nullable    = false
}

variable "logs_agent_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs agent ignores."
  default     = []
  nullable    = false
}

variable "logs_agent_selected_log_source_paths" {
  type        = list(string)
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. When specified logs from only these namespaces will be sent by the agent."
  default     = []
  nullable    = false
}

variable "logs_agent_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`."
}

variable "logs_agent_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "logs_agent_enable_scc" {
  description = "Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster."
  type        = bool
  default     = true
}

variable "cloud_logs_ingress_endpoint" {
  description = "The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress. It is required if `logs_agent_enabled` is set to true."
  type        = string
  default     = null
}

variable "cloud_logs_ingress_port" {
  type        = number
  default     = 3443
  description = "The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
}
