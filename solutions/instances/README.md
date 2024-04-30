# IBM Cloud observability instances deployable architecture

This deployable architecture creates observability instances in IBM Cloud and supports provisioning the following resources:

- A resource group, if one is not already passed in.
- A Log Analysis instance.
- A Cloud Monitoring instance.
- A Cloud Object Storage instance, if one exists, or creates an instance.
- A key management service (KMS) instance that contains KMS root keys when buckets are created, or creates KMS root keys in an existing KMS instance.
- A KMS encrypted bucket, if one exists. Or, creates a KMS encrypted Cloud Object Storage bucket that is required to store archived logs.
- A KMS encrypted Cloud Object Storage bucket, if one exists, Or, creates a KMS encrypted Cloud Object Storage bucket for setting up Activity Tracker event routing.
- An Activity Tracker event route to a Cloud Object Storage target.

![observability-instances-deployable-architecture](../../reference-architecture/deployable-architecture-observability-instances.svg)

**Important:** Because this solution contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments, do not call this solution from one or more other modules. For more information about how resources are associated with provider configurations with multiple modules, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
