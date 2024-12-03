---

copyright:
  years: 2024
lastupdated: "2024-12-06"

subcollection: deployable-reference-architectures

authors:
- name: Shikha Maheshwari

# The release that the reference architecture describes
version: 2.4.1

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page for the deployable architecture.
# See https://test.cloud.ibm.com/docs/get-coding?topic=get-coding-deploy-button
deployment-url: https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-observability-a3137d28-79e0-479d-8a24-758ebd5a0eab-global

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-observability-da/blob/main/reference-architecture/deployable-architecture-observability-instances.svg

use-case:
  - Observability
  - PlatformLogging
  - PlatformMonitoring
  - ATEventsRouting

industry: SoftwareAndPlatformApplications, Technology, ITConsulting, FinancialSector

compliance:

docs: https://cloud.ibm.com/docs/observability-hub?topic=observability-hub-overview

content-type: reference-architecture

production: true

---

{{site.data.keyword.attribute-definition-list}}



# Cloud Automation for Observability
{: #observability-deployable-architecture}
{: toc-content-type="reference-architecture"}

Observability is iportant for ensuring reliability and scalability in the distributed and cloud-based architectures. This deployable architecture simplifies and automates the organization's observability configuration, the associated dependencies and its maintenance.

This deployable architecture includes:

1. {{site.data.keyword.keymanagementserviceshort}}

{{site.data.keyword.keymanagementserviceshort}} is responsible for centrally managing the lifecycle of encryption keys that are used by {{site.data.keyword.cos_full_notm}} buckets. Additionally, it can manage encryption keys for any customer workload that requires protection.

2. {{site.data.keyword.cos_full_notm}}

{{site.data.keyword.cos_full_notm}} buckets are utilized to store logs, events, and metrics. All data stored in {{site.data.keyword.cos_full_notm}} is encrypted for security.

3. {{site.data.keyword.monitoringlong_notm}}

{{site.data.keyword.monitoringlong_notm}} is used to store platform metrics and, by default, collects them automatically. Additionally, you can extend its capabilities by adding custom metrics.

4. {{site.data.keyword.logs_full_notm}}

{{site.data.keyword.logs_full_notm}} is used to store platform logs, which are enabled by default. You can configure {{site.data.keyword.cos_full_notm}} buckets to store your {{site.data.keyword.logs_full_notm}} data and metrics from logs for long term storage and search. Additionally, {{site.data.keyword.logs_full_notm}} policies can be setup to better control the data that is ingested, and manage the data available for search within CL.


5. {{site.data.keyword.en_full_notm}}

It supports integration with {{site.data.keyword.en_full_notm}} to gather notification events, which can then be configured to consume notifications.


## Architecture diagram
{: #architecture-diagram}

The following diagram represents the architecture for the Cloud Automation for Observability deployable architecture.

![Architecture.](deployable-architecture-observability-instances.svg "Architecture"){: caption="Figure 1. Architecture diagram" caption-side="bottom"}{: external download="deployable-architecture-observability-instances.svg"}

The Cloud automation for Observability deployable architecture automates the following.

- creates the {{site.data.keyword.monitoringlong_notm}} and the {{site.data.keyword.logs_full_notm}} instances.
- configures routing of the cloud platform activity events to the {{site.data.keyword.logs_full_notm}} and the {{site.data.keyword.cos_full_notm}} bucket.
- configures routing of the cloud platform logs and the metrics from logs to {{site.data.keyword.cos_full_notm}} buckets.
- integration of {{site.data.keyword.en_full_notm}} with {{site.data.keyword.logs_full_notm}}.
- it also supports provisioning of a resource group, root keys in an existing key management service (KMS), {{site.data.keyword.cos_full_notm}} instance and KMS encrypted {{site.data.keyword.cos_full_notm}} buckets.

It requires the `crn` of the KMS instance as a required input. You can also provide the KMS key crn for encryption. If you do not specify an KMS key, then the deployable architecture automatically creates one for you in a key ring of your choice (if you do not specify a key ring, then the default one is used).

You can provide the existing {{site.data.keyword.cos_full_notm}} instance and {{site.data.keyword.cos_full_notm}} buckets to store logs and events. If you do not specify existing {{site.data.keyword.cos_full_notm}} or {{site.data.keyword.cos_full_notm}} bucket details, then it creates the required infrastructure for you. Each bucket is configured to encrypt data at rest by using encryption keys managed by {{site.data.keyword.keymanagementserviceshort}}.

## Design concepts
{: #design-concepts}

- Storage: Backup, Archive
- Networking: Cloud-native connectivity
- Security: Identity and access, governance, risk and compliance
- Resiliency: Backup & restore
- Service management: Monitoring, logging, auditing and tracking, alerting, automated deployment, management/orchestration

![heatmap](heat-map-observability-da.svg "Current diagram"){: caption="Architecture design scope" caption-side="bottom"}{: external download="heat-map-observability-da.svg"}

## Requirements
{: #requirements}

The following table outlines the requirements that are addressed in this architecture.

| Aspect | Requirements |
| -------------- | -------------- |
| Security           | Encrypt all application data in transit and at rest to protect it from unauthorized disclosure. \n Encrypt all security data (operational and audit logs) to protect from unauthorized disclosure. \n Encrypt all data using customer-managed keys to meet regulatory compliance requirements for additional security and customer control. |
| Resiliency         | Support application availability targets and business continuity policies. \n Ensure availability of the application during planned and unplanned outages. \n Back up application data to enable recovery during unplanned outages. \n Provide highly available storage for security data (logs) and backup data. |
| Service Management | Monitor system and application health metrics and logs to detect issues that might impact the availability of the application. \n Generate alerts/notifications about issues that might impact the availability of applications to trigger appropriate responses to minimize downtime. \n Monitor audit logs to track changes and detect potential security problems. \n Provide a mechanism to identify and send notifications about issues that are found in audit logs. |
{: caption="Requirements" caption-side="bottom"}

## Components
{: #components}

The following table outlines the products or services used in the architecture for each aspect.

| Aspects | Architecture components | How the component is used |
| -------------- | -------------- | -------------- |
| Storage | [{{site.data.keyword.cos_full_notm}}](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-about-cloud-object-storage) | Web app static content, backups, logs (application, operational, and audit logs) |
| Networking | [Virtual Private Endpoint (VPE)](https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpe) | For private network access to {{site.data.keyword.cloud_notm}} services, for example, {{site.data.keyword.keymanagementserviceshort}}. |
| Security | [IAM](https://cloud.ibm.com/docs/account?topic=account-cloudaccess) | {{site.data.keyword.iamshort}} |
|  | [{{site.data.keyword.keymanagementserviceshort}}](https://cloud.ibm.com/docs/key-protect?topic=key-protect-about) | A full-service encryption solution that allows data to be secured and stored in {{site.data.keyword.cloud_notm}} |
| Service Management | [{{site.data.keyword.monitoringlong_notm}}](https://cloud.ibm.com/docs/monitoring?topic=monitoring-about-monitor) | Apps and operational monitoring |
|  | [{{site.data.keyword.logs_full_notm}}](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-getting-started) | Apps and operational logs |
|  | [{{site.data.keyword.atracker_short}}](https://cloud.ibm.com/docs/activity-tracker?topic=activity-tracker-getting-started) | Audit logs |
{: caption="Table 2. Components" caption-side="bottom"}


## Compliance
{: #compliance}

Ensures compliance with some of the controls in the {{site.data.keyword.framework-fs_full}} profile. To view the list of added controls, follow these steps:

1.  Go the {{site.data.keyword.cloud_notm}} [catalog](/catalog#reference_architecture){: external} and search for the Cloud Automation for Observability deployable architecture.
1.  Click the tile for the deployable architecture to open the details. The Security & compliance tab lists all of the controls that are included in the deployable architecture.
