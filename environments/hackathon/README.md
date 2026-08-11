# Hackathon Environment Configuration

This folder houses the target overlay configurations and contracts for the Hackathon environment.

## Required Operator Inputs
Before running the bootstrap/setup scripts, the operator MUST supply/configure the following parameters:

1. **Kubernetes Target Context**:
   Set `kubernetes.targetContext` in [environment.yaml](file:///f:/AI-AAD/aiaad-infra/environments/hackathon/environment.yaml) to match your active CLI context (e.g. `brave-lion-admin` or `phoenix`).
   
2. **Workload Identity Client IDs**:
   Kubernetes ServiceAccounts will federate with Azure User-Assigned Managed Identities (UAMIs). Ensure UAMI resource IDs / client IDs are provisioned and mapped where required (e.g. in [identity/README.md](file:///f:/AI-AAD/aiaad-infra/identity/README.md)).

3. **External Secret References**:
   Ensure external dependency credentials (Neo4j passwords, Azure AI Foundry keys) are populated securely using the cluster's secret store (e.g., CSO or Azure Key Vault Provider).
