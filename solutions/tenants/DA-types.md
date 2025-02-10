# Configuring Tenants for Log Routing to Cloud Logs Instances

When you create a log router tenant from the IBM cloud catalog you can configure in which region you want to create the router tenant 

and which cloud logs instance you want to target  and give names to the tenant and the target

### Options for tenant configuration
- `tenant_region` (required): The region in which the tenant will be created
- `tenant_name` (required): The name of the tenant which has to be created
- `target_name` (required): The name to be given to the target inside the tenant
- `log_sink_crn` (required): The Cloud Resource Name (CRN) of the cloud logs instance where logs will be routed.

### Example log router tenant configuration

```hcl
tenant_configuration = [
    {
      tenant_region = "eu-de"
      tenant_name   = "test-tenant-1"
      target_name       = "test-target-1"
      log_sink_crn      = "crn:v1:bluemix:public:logs:us-south::2fde707d-7cb6-4aed-80df-ab038599872c::"
    },
    {
      tenant_region = "br-sao"
      tenant_name   = "test-tenant-2"
      target_name       = "test-target-2"
      log_sink_crn      = "crn:v1:bluemix:public:logs:us-south::2fde707d-7cb6-4aed-80df-ab038599872c::"
    }
]
```