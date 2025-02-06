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

# Configuring complex inputs in IBM Cloud Object Storage in IBM Cloud projects
Several optional input variables in the IBM Cloud Object Storage [deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You specify these inputs when you configure your deployable architecture.

- [Resource keys](#resource-keys) (`resource_keys`)
- [Service credential secrets](#service-credential-secrets) (`service_credential_secrets`)

## Resource keys <a name="resource-keys"></a>
When you add an IBM Cloud Object Storage service from the IBM Cloud catalog to an IBM Cloud Projects service, you can configure resource keys. In the edit mode for the projects configuration, select the Configure panel and then click the optional tab.

In the configuration, specify the name of the resource key, whether HMAC credentials should be included, the Role of the key and an optional Service ID CRN to create with a Service ID.

To enter a custom value, use the edit action to open the "Edit Array" panel. Add the resource key configurations to the array here.

 [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key) about resource keys.

- Variable name: `resource_keys`.
- Type: A list of objects that represent a resource key
- Default value: An empty list (`[]`)

### Options for resource_key

- `name` (required): A unique human-readable name that identifies this resource key.
- `generate_hmac_credentials` (optional, default = `false`): Set to true to include COS HMAC keys in the resource key. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key#example-to-create-by-using-hmac).
- `role` (optional, default = `Reader`): The name of the user role.
- `service_id_crn` (optional, default = `null`): Pass a Service ID CRN to create credentials for a resource with a Service ID. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/resource_key#example-to-create-by-using-serviceid).

The following example includes all the configuration options for two resource keys. One is a key with a `Reader` role, the other with a `Writer` role.
```hcl
    [
      {
        "name": "da-reader-resource-key",
        "generate_hmac_credentials": "false",
        "role": "Reader",
        "service_id_crn": null
      },
      {
        "name": "da-writer-resource-key",
        "role": "Writer"
      }
    ]
```

## Service credential secrets <a name="service-credential-secrets"></a>
When you add an IBM Cloud Object Storage service from the IBM Cloud catalog to an IBM Cloud Projects service, you can configure service credentials. In the edit mode for the projects configuration, select the Configure panel and then click the optional tab.

In the configuration, specify the secret group name, whether it already exists or will be created and include all the necessary service credential secrets that need to be created within that secret group.

To enter a custom value, use the edit action to open the "Edit Array" panel. Add the service credential secrets configurations to the array here.

 [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/sm_service_credentials_secret) about service credential secrets.

- Variable name: `service_credential_secrets`.
- Type: A list of objects that represent a service credential secret groups and secrets
- Default value: An empty list (`[]`)

### Options for service_credential_secrets

- `secret_group_name` (required): A unique human-readable name that identifies this service credential secret group.
- `secret_group_description` (optional, default = `null`): A human-readable description for this secret group.
- `existing_secret_group`: (optional, default = `false`): Set to true, if secret group name provided in the variable `secret_group_name` already exists.
- `service_credentials`: (optional, default = `[]`): A list of object that represents a service credential secret.

### Options for service_credentials

- `secret_name`: (required): A unique human-readable name of the secret to create.
- `service_credentials_source_service_role_crn`: (required): The CRN of the role to give the service credential in the COS service. Service credentials role CRNs can be found at https://cloud.ibm.com/iam/roles, select Cloud Object Storage and select the role.
- `secret_labels`: (optional, default = `[]`): Labels of the secret to create. Up to 30 labels can be created. Labels can be 2 - 30 characters, including spaces. Special characters that are not permitted include the angled brackets (<>), comma (,), colon (:), ampersand (&), and vertical pipe character (|).
- `secret_auto_rotation`: (optional, default = `true`): Whether to configure automatic rotation of service credential.
- `secret_auto_rotation_unit`: (optional, default = `day`): Specifies the unit of time for rotation of a secret. Acceptable values are `day` or `month`.
- `secret_auto_rotation_interval`: (optional, default = `89`): Specifies the rotation interval for the rotation unit.
- `service_credentials_ttl`: (optional, default = `7776000`): The time-to-live (TTL) to assign to generated service credentials (in seconds).
- `service_credential_secret_description`: (optional, default = `null`): Description of the secret to create.

The following example includes all the configuration options for four service credentials and two secret groups.
```hcl
[
  {
    "secret_group_name": "sg-1"
    "existing_secret_group": true
    "service_credentials": [ # pragma: allowlist secret
      {
        "secret_name": "cred-1"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Reader"
        "secret_labels": ["test-reader-1", "test-reader-2"]
        "secret_auto_rotation": true
        "secret_auto_rotation_unit": "day"
        "secret_auto_rotation_interval": 89
        "service_credentials_ttl": 7776000
        "service_credential_secret_description": "sample description"
      },
      {
        "secret_name": "cred-2"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Writer"
      }
    ]
  },
  {
    "secret_group_name": "sg-2"
    "service_credentials": [ # pragma: allowlist secret
      {
        "secret_name": "cred-3"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:iam::::serviceRole:Manager"
      },
      {
        "secret_name": "cred-4"
        "service_credentials_source_service_role_crn": "crn:v1:bluemix:public:cloud-object-storage::::serviceRole:ContentReader"
      }
    ]
  }
]
```
