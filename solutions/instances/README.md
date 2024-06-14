# IBM Cloud observability instances deployable architecture

This deployable architecture creates observability instances in IBM Cloud and supports provisioning the following resources:

* A resource group, if one is not passed in.
* An IBM Cloud Log Analysis instance.
* An IBM Cloud Monitoring instance.
* An IBM Cloud Object Storage instance, if one does not exist.
* The root keys in an existing key management service (KMS) if the keys do not exist. These keys are used when Object Storage buckets are created.
* A KMS-encrypted Object Storage bucket to store archived logs, if one is not passed in.
* A KMS-encrypted Object Storage bucket for Activity Tracker event routing, if one is not passed in.
* An Activity Tracker event route to an Object Storage and Log Analysis target.

![observability-instances-deployable-architecture](../../reference-architecture/deployable-architecture-observability-instances.svg)

**Important:** Because this solution contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments, do not call this solution from one or more other modules. For more information about how resources are associated with provider configurations with multiple modules, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
