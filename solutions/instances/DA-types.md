# Configuring complex inputs for Cloud Automation for Observability

Several optional input variables in the IBM Cloud [Observability instances deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You specify these inputs when you configure deployable architecture.

* Cloud Logs Event Notification Instances (`cloud_logs_existing_en_instances`)
* Cloud Logs policies (`cloud_logs_policies`)
* Metrics Router Routes (`metrics_router_routes`)
* Activity Tracker Event Routing COS bucket retention policy (`at_cos_bucket_retention_policy`)
* Cloud Logs data bucket retention policy(`cloud_log_data_bucket_retention_policy`)


## Cloud Logs Event Notification Instances <a name="cloud_logs_existing_en_instances"></a>

The `cloud_logs_existing_en_instances` input variable allows you to provide a list of existing Event Notification (EN) instances that will be integrated with the Cloud Logging service. For each EN instance, you need to specify its CRN (Cloud Resource Name). You can also optionally configure a integration name and control whether to skip the creation of an authentication policy for the instance.

- Variable name: `cloud_logs_existing_en_instances`.
- Type: A list of objects. Each object represents an EN instance.
- Default value: An empty list (`[]`).

### Options for cloud_logs_existing_en_instances

  - `instance_crn` (required): The Cloud Resource Name (CRN) of the Event Notification instance.
  - `integration_name` (optional): The name of the Event Notification integration that gets created. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format. Defaults to `"cloud-logs-en-integration"`.
  - `skip_en_auth_policy` (optional): A boolean flag to determine whether to skip the creation of an authentication policy that allows Cloud Logs 'Event Source Manager' role access in the existing event notification instance. Defaults to `false`.

### Example Event Notification Instance Configuration

```hcl
cloud_logs_existing_en_instances = [
  {
    instance_crn        = "crn:v1:bluemix:public:...:event-notifications:instance"
    integration_name    = "custom-logging-en-integration"
    skip_en_auth_policy = true
  },
  {
    instance_crn        = "crn:v1:bluemix:public:...:event-notifications:instance"
    skip_en_auth_policy = false
  }
]
```

In this example:
- The first EN instance has a integration name `"custom-logging-en-integration"` and skips the authentication policy.
- The second EN instance uses the default integration name and includes the authentication policy.

## Cloud Logs Policies <a name="cloud_logs_policies"></a>

The `cloud_logs_policies` input variable allows you to provide a list of policies that will be configured in the Cloud Logs service. Refer [here](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-tco-optimizer) for more information.

- Variable name: `cloud_logs_policies`.
- Type: A list of objects. Each object represents a policy.
- Default value: An empty list (`[]`).

### Options for cloud_logs_policies

  - `logs_policy_name` (required): The unique policy name.
  - `logs_policy_description` (optional): The description of the policy to create.
  - `logs_policy_priority` (required): The priority to determine the pipeline for the logs. Allowed values are: type_unspecified, type_block, type_low, type_medium, type_high. High (priority value) sent to 'Priority insights' (TCO pipleine), Medium to 'Analyze and alert', Low to 'Store and search', Blocked are not sent to any pipeline.
  - `application_rule` (optional): The rules to include in the policy configuration for matching applications.
  - `subsystem_rule` (optional): The subsystem rules to include in the policy configuration for matching applications.
  - `log_rules` (required): The log severities to include in the policy configuration.
  - `archive_retention` (optional): Define archive retention.

### Example cloud_logs_policies

```hcl
cloud_logs_policies = [
  {
    logs_policy_name     = "logs-policy-1"
    logs_policy_description = "Send info and debug logs of the application (name starts with `test-system-app`) and the subsytem (name starts with `test-sub-system`) logs to Store nad search pipeline"
    logs_policy_priority = "type_low"
    application_rule = [{
      name         = "test-system-app"
      rule_type_id = "start_with"
    }]
    log_rules = [{
      severities = ["info", "debug"]
    }]
    subsystem_rule = [{
      name         = "test-sub-system"
      rule_type_id = "start_with"
    }]
  },
  {
    logs_policy_name     = "logs-policy-2"
    logs_policy_description = "Send error logs of all applications and all subsystems to Analyze and Alert pipeline"
    logs_policy_priority = "type_medium"
    log_rules = [{
      severities = ["error"]
    }]
  }
]
```

## Metrics Router Routes <a name="metrics_router_routes"></a>

The `metrics_router_routes` input variable allows you to provide a list of routes that will be configured in the IBM Cloud Metrics Routing. Refer [here](https://cloud.ibm.com/docs/metrics-router?topic=metrics-router-about) for more information.

- Variable name: `metrics_router_routes`.
- Type: A list of objects. Each object represents a route.
- Default value: An empty list (`[]`).

### Options for metrics_router_routes

  - `name` (required):  The name of the route.
  - `rules` (required): The routing rules that will be evaluated in their order of the array. You can configure up to 10 rules per route.
    - `action` (optional): The action if the inclusion_filters matches, default is send action. Allowed values are `send` and `drop`.
    - `inclusion_filters` (required): A list of conditions to be satisfied for routing metrics to pre-defined target.'inclusion_filters' is an object with three parameters:
        - `operand` - Part of CRN that can be compared with values. Allowable values are: `location`, `service_name`, `service_instance`, `resource_type`, `resource`.

        - `operator` - The operation to be performed between operand and the provided values. Allowable values are: `is`, `in`.

        - `values` - The provided string values of the operand to be compared with.
    - `targets` (required): The target uuid for a pre-defined metrics router target.

### Example metrics_router_routes

```hcl
metrics_router_routes = {
    name = "my-route"
    rules {
      action = "send"
      targets {
        id = "c3af557f-fb0e-4476-85c3-0889e7fe7bc4"
      }
      inclusion_filters {
        operand = "location"
        operator = "is"
        values = [ "us-south" ]
      }
    }
}
```
Refer [here](https://cloud.ibm.com/docs/metrics-router?topic=metrics-router-route_rules_definitions&interface=ui) for more information about IBM Cloud Metrics Routing route.


## Metrics Router Settings <a name="metrics_router_settings"></a>

The `metrics_router_settings` input variable allows you configure global settings for Metrics Routing. Refer [here](https://cloud.ibm.com/docs/metrics-router?topic=metrics-router-settings-about&interface=ui) for more information.

- Variable name: `metrics_router_settings`.
- Type: A list of objects. Each object represents a route.
- Default value: An empty list (`[]`).

### Options for metrics_router_settings

  - `default_targets` (optional): (List) -  A list of default target references.
  - `permitted_target_regions` (optional):(List)  If present then only these regions may be used to define a target.
  - `primary_metadata_region` (optional): To store all your meta data in a single region. For new accounts, all target / route creation will fail until primary_metadata_region is set.
  - `backup_metadata_region` (optional): To backup all your meta data in a different region.
  - `private_api_endpoint_only` (optional): If you set this true then you cannot access api through public network.

### Example metrics_router_settings

```hcl
metrics_router_settings = {
  default_targets = [
    "f3a1b2c4-89d7-4e6f-9153-2d6a8f9e0b7c",
    "7d5e2f1a-cb34-4679-823a-1f9c0e8d5b6a",
    "ae89c3f5-42d1-4b7e-9f62-8d0e7a1b4c5f",
  ]
  permitted_target_regions = ["us-south", "eu-de", "us-east", "eu-es", "eu-gb", "au-syd", "br-sao", "ca-tor", "jp-tok", "jp-osa"]
  primary_metadata_region = "eu-de"
  backup_metadata_region = "us-east"
  private_api_endpoint_only = true
}
```
Refer [here](https://cloud.ibm.com/docs/metrics-router?topic=metrics-router-settings&interface=ui) for more information about IBM Cloud Metrics Routing Settings.


## Event Router Settings <a name="global_event_routing_settings"></a>

The `global_event_routing_settings` input variable allows you configure global settings for Activity Tracker Event Routing. Refer [here](https://cloud.ibm.com/docs/atracker?topic=atracker-settings&interface=ui) for more information.

- Variable name: `global_event_routing_settings`.
- Type: A list of objects. Each object represents a route.
- Default value: An empty list (`[]`).

### Options for global_event_routing_settings

  - `default_targets` (optional): (List) -  The target ID List. In the event that no routing rule causes the event to be sent to a target, these targets will receive the event.
  - `metadata_region_primary` (required): To store all your meta data in a single region.
  - `metadata_region_backup` (optional): The routing rules that will be evaluated in their order of the array. You can configure up to 10 rules per route.
  - `permitted_target_regions` (required):(List)  If present then only these regions may be used to define a target.
  - `private_api_endpoint_only` (optional): If you set this true then you cannot access api through public network.

### Example global_event_routing_settings

```hcl
global_event_routing_settings = {
  default_targets           = [
    "f3a1b2c4-89d7-4e6f-9153-2d6a8f9e0b7c",
    "7d5e2f1a-cb34-4679-823a-1f9c0e8d5b6a",
    "ae89c3f5-42d1-4b7e-9f62-8d0e7a1b4c5f",
  ]
  metadata_region_primary   = "eu-de"
  metadata_region_backup    = "us-south"
  permitted_target_regions  = ["us-south", "eu-de", "us-east", "eu-es", "eu-gb", "au-syd", "br-sao", "ca-tor", "eu-es", "jp-tok", "jp-osa", "in-che", "eu-fr2"]
  private_api_endpoint_only = true
}
```

## at_cos_bucket_retention_policy <a name="at_cos_bucket_retention_policy"></a>

The `at_cos_bucket_retention_policy` input variable allows you to provide the retention policy of the IBM Cloud Activity Tracker Event Routing COS target bucket that will be configured. Refer [here](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-immutable) for more information.

- Variable name: `at_cos_bucket_retention_policy`.
- Type: An object representing a retention policy.
- Default value: null (`null`).

### Options for at_cos_bucket_retention_policy

- `default` (optional): The number of days that an object can remain unmodified in an Object Storage bucket.
- `maximum` (optional): The maximum number of days that an object can be kept unmodified in the bucket.
- `minimum` (optional): The minimum number of days that an object must be kept unmodified in the bucket.
- `permanent` (optional): Whether permanent retention status is enabled for the Object Storage bucket.

### Example at_cos_bucket_retention_policy

```hcl
at_cos_bucket_retention_policy = {
    default   = 90
    maximum   = 350
    minimum   = 90
    permanent = false
}
```

## cloud_log_data_bucket_retention_policy <a name="cloud_log_data_bucket_retention_policy"></a>

The `cloud_log_data_bucket_retention_policy` input variable allows you to provide the retention policy of the IBM Cloud Logs data bucket that will be configured. Refer [here](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-immutable) for more information.

- Variable name: `cloud_log_data_bucket_retention_policy`.
- Type: An object representing a retention policy.
- Default value: null (`null`).

### Options for cloud_log_data_bucket_retention_policy

- `default` (optional): The number of days that an object can remain unmodified in an Object Storage bucket.
- `maximum` (optional): The maximum number of days that an object can be kept unmodified in the bucket.
- `minimum` (optional): The minimum number of days that an object must be kept unmodified in the bucket.
- `permanent` (optional): Whether permanent retention status is enabled for the Object Storage bucket.



### Example cloud_log_data_bucket_retention_policy

```hcl
cloud_log_data_bucket_retention_policy = {
    default   = 90
    maximum   = 350
    minimum   = 90
    permanent = false
}
```
