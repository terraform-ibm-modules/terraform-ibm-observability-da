# IBM Observability Instances Deployable Architecture

This architecture creates the observability instances on IBM Cloud and supports provisioning the following resources:

- A resource group, if one is not passed in.
- A log analysis instance.
- A cloud monitoring instance.
- Creates a cloud object storage(COS) instance or taking in an existing one.
- Creates a KMS encrypted COS bucket that is required to store archived logs or using the existing one.
- Creates a KMS encrypted COS bucket for setting up Activity Tracker event routing or using the existing one.

![observability-instances-deployable-architecure](../../reference-architecture/deployable-architecture-observability-instances.svg)

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
