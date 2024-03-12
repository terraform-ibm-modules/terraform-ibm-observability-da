# IBM Observability Instances Deployable Architecture

This architecture creates an observability instances on IBM Cloud®  and supports provisioning the following resources:

- A resource group, if one is not passed in.
- A log analysis instance,
- A cloud monitoring instance,
- Provisions a cloud object storage(COS) instance and KMS encrypted bucket which is required to store log archives.
- Provisions another KMS encrypted COS bucket for setting up Activity Tracker event routing.

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
