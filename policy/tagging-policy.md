Tagging Policy

Purpose

Tags provide ownership, cost allocation, environment identification, and data-classification metadata for Azure resources.

Required Governance Tags

Tag| Example| Purpose
"env"| "dev", "test", "prod"| Identifies the deployment lifecycle stage
"owner"| "platform-team@company.com"| Identifies the accountable team or contact
"costCenter"| "CC1001"| Supports chargeback and cost reporting
"app"| "cloud-org-portal"| Associates the resource with an application or workload
"dataClass"| "internal", "confidential"| Records the data-classification level

Automation Baseline

Resource-group deployment currently applies these baseline tags:

Tag| Source
"environment"| Deployment environment parameter
"app"| Application parameter
"region"| Region parameter
"owner"| "cloud-org-infra" default

Additional resource-group tags can be supplied through the "AdditionalTags" parameter.

Rules

- Apply the required governance tags when resources are created.
- Use controlled values for environment and data classification.
- Do not store secrets, credentials, or personal data in tags.
- Review and remediate missing or invalid tags before production approval.
- Keep tag values consistent across a resource group and its resources.
- Apply tags explicitly to resources because Azure resource-group tags are not inherited automatically.

Governance

"policy/policies/require-tags.json" audits the presence of "env", "owner", "costCenter", "app", and "dataClass".

The current policy effect is "auditIfNotExists". Non-compliant resources are reported but deployment is not blocked.

The automation baseline currently uses "environment", while the Azure Policy definition checks "env". Standardizing these keys and applying the complete governance tag set to individual resources should be handled as a separate implementation change.