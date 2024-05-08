# IBM Observability Instances Deployable Architecture

This architecture creates the observability instances on IBM Cloud and supports provisioning the following resources:

- A resource group, if one is not passed in.
- A Log Analysis instance.
- A Cloud Monitoring instance.
- Creates a Cloud Object Storage (COS) instance or supports using an existing one.
- Supports creating KMS root keys in an existing KMS instance or using existing keys if creating new buckets.
- Creates a KMS encrypted COS bucket that is required to store archived logs or using an existing bucket.
- Creates a KMS encrypted COS bucket for setting up Activity Tracker event routing or using an existing bucket.
- Configures an Activity Tracker event routing to a COS bucket.
- Optionally configures an Activity Tracker event routing to a Log Analysis instance.

![observability-instances-deployable-architecture](../../reference-architecture/deployable-architecture-observability-instances.svg)

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
