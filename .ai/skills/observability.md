# Observability
- Reuse observability facilities already present in AKS where possible.
- Do not deploy a competing monitoring stack without explicit approval.
- Infra diagnostics should report component readiness, restarts, persistence, Kafka availability, Temporal health and external-dependency reachability.
- Logs must avoid secrets/confidential documents.
- Prefer one aggregated infra-health command/report for operators.
