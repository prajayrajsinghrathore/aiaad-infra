# Identity and secrets
- Identity-based access uses the organisation's UAMI + federated workload-identity pattern.
- Infrastructure templates reference approved identity IDs/client IDs supplied externally; do not create/guess them.
- Respect existing ESI/CSO secret/identity integration used by the cluster.
- Never commit PATs, passwords, Neo4j credentials, tokens, client secrets or Kubernetes Secret values.
- ADO PAT is injected only where needed later by the ADO connector/diagnostic.
- Prefer workload identity for Azure Blob and Foundry/OpenAI.
- Secrets/config are injected through the approved environment/deployment mechanism; example files contain placeholders only.
- Never print secret values in smoke-test output or logs.
