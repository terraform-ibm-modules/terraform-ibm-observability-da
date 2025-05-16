moved {
  from = module.observability_agents.module.logs_agent[0].helm_release.logs_agent
  to   = module.logs_agent[0].helm_release.logs_agent
}

# Unable to use below moved block because the helm chart in observability_agents 
# cannot be updated in place to the helm chart in monitoring_agent as it will fail with:
#   Error: failed to replace object: DaemonSet.apps "cc-sysdig-agent" is invalid: spec.selector: 
#   Invalid value: v1.LabelSelector{MatchLabels:map[string]string{"app.kubernetes.io/instance":"cc-sysdig-agent", 
#   "app.kubernetes.io/name":"agent"}, MatchExpressions:[]v1.LabelSelectorRequirement(nil)}: field is immutable

# moved {
#   from = module.observability_agents.helm_release.cloud_monitoring_agent[0]
#   to   = module.monitoring_agent[0].helm_release.cloud_monitoring_agent
# }
