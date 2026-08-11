# aiaad-infra TODOs

This file tracks pending tasks and deferred configurations for the infrastructure repository.

## Azure Environment Configuration
- [x] Update Azure Subscription ID across configuration files.
- [x] Update Azure Tenant ID across configuration files.
- [ ] Connect to Azure Storage Account for production/remote object storage (deferred from INF-10, currently using local MinIO).
- [ ] Configure Workload Identity (UAMI) / Federated identity for AKS.

## Infrastructure Work Packages
- [ ] Complete remaining INF work packages as required.
- [ ] Set up production-grade PostgreSQL (if not using local deployment).
- [ ] Update the SharePoint endpoint in the connectivity diagnostic scripts with the correct tenant URL (currently uses placeholder `microsoft.sharepoint.com` causing DNS failures).
- [ ] Configure the OpenAI API endpoint and credentials/service account to pass the connectivity tests.
- [ ] Refactor the main smoke test suite (`smoke/run-all.sh` and `smoke/run-all.ps1`) to invoke the specialized diagnostic scripts (`neo4j-connectivity`, `openai`, `ado-graph-connectivity`) instead of using hardcoded URLs.
