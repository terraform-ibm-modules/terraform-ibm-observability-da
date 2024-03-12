# IBM Observability Instance Deployable Architecture

This architecture creates an observability instance on IBM Cloud®  and supports provisioning the following resources:

- A resource group, if one is not passed in.
- An observability instance which contains Log Analysis, Cloud Monitoring and Activity Tracker instance.
- Provisioning of a COS instance and KMS encrypted bucket which is required to store log archives.
- Provisioning of another KMS encrypted cos bucket for setting up event routing.

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
