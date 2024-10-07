# Configuring Event Notification (EN) Instances for Cloud Logging

Several optional input variables in the IBM Cloud [Observability instances deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You specify these inputs when you configure deployable architecture.

- [Cloud Logs Event Notification Instances](#cloud_logs_existing_en_instances) (`cloud_logs_existing_en_instances`)

## Cloud Logs Event Notification Instances <a name="cloud_logs_existing_en_instances"></a>

The `cloud_logs_existing_en_instances` input variable allows you to provide a list of existing Event Notification (EN) instances that will be integrated with the Cloud Logging service. For each EN instance, you need to specify its CRN (Cloud Resource Name). You can also optionally configure a integration name and control whether to skip the creation of an authentication policy for the instance.

- Variable name: `cloud_logs_existing_en_instances`.
- Type: A list of objects. Each object represents an EN instance with the following attributes:
  - `instance_crn` (required): The Cloud Resource Name (CRN) of the Event Notification instance.
  - `integration_name` (optional): The name of the event notification integration that gets created. If a prefix input variable is passed, it is prefixed to the value in the `<prefix>-value` format. Defaults to `"cloud-logs-en-integration"`.
  - `skip_en_auth_policy` (optional): A boolean flag to determine whether to skip the creation of an authentication policy that allows Cloud Logs 'Event Source Manager' role access in the existing event notification instance. Defaults to `false`.
- Default value: An empty list (`[]`).


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