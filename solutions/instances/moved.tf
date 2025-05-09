moved {
  from = module.observability_instance.module.metric_routing
  to   = module.metrics_router
}

moved {
  from = module.observability_instance.module.cloud_logs[0]
  to   = module.cloud_logs[0]
}

moved {
  from = module.observability_instance.module.cloud_monitoring[0].ibm_resource_instance.cloud_monitoring[0]
  to   = module.cloud_monitoring[0].ibm_resource_instance.cloud_monitoring
}

moved {
  from = module.observability_instance.module.cloud_monitoring[0].ibm_resource_key.resource_key[0]
  to   = module.cloud_monitoring[0].ibm_resource_key.resource_key
}

moved {
  from = module.observability_instance.module.cloud_monitoring[0].ibm_resource_tag.cloud_monitoring_tag
  to   = module.cloud_monitoring[0].ibm_resource_tag.cloud_monitoring_tag
}

moved {
  from = module.observability_instance.module.activity_tracker
  to   = module.activity_tracker
}
