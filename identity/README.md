# Workload Identity & Service Accounts

This directory defines the templates and patterns for mapping Kubernetes ServiceAccounts to Azure User-Assigned Managed Identities (UAMIs) using Azure AD Workload Identity.

## Annotations & Labels
For Workload Identity federation, the ServiceAccount must be annotated with:
- `azure.workload.identity/client-id`: The Client ID of the User-Assigned Managed Identity.
- `azure.workload.identity/tenant-id`: The Directory (Tenant) ID of the Azure Tenant.

And the Pod spec must include the label:
- `azure.workload.identity/use: "true"`
- `spec.serviceAccountName`: The name of the annotated ServiceAccount.

## Templates
- [serviceaccount.yaml](file:///f:/AI-AAD/aiaad-infra/identity/workload-identity/templates/serviceaccount.yaml)
- [test-pod.yaml](file:///f:/AI-AAD/aiaad-infra/identity/workload-identity/templates/test-pod.yaml)
