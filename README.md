# aiaad-infra

Repository for provisioning the shared infrastructure workloads for the AI Hackathon.

## Repository Layout
This repository is organized logically by component and concern:
- **`.ai/skills/`**: Contains agent guidelines and architectural constraints.
- **`namespaces/`**: Defines the two target namespaces: `aiaad-infra` and `aiaad-platform`.
- **`bootstrap/`**: Idempotent entrypoint scripts (`bootstrap.sh`, `bootstrap.ps1`) and prerequisite checkers.
- **`helm/`**: Base values and hackathon overlays for PostgreSQL, Temporal, Kafka, etc.
- **`istio/`**: Configuration documenting the existing Gateway reference andVirtualServices.
- **`identity/`**: Configurations for Kubernetes service accounts and federated workload identity.
- **`postgres/`**: Initialization scripts (databases, pgvector, roles) and verification scripts.
- **`environments/hackathon/`**: Contains target configuration overlays.
- **`admin/`**: Troubleshooting connectivity diagnostics and port-forwarding scripts.
- **`smoke/`**: Verification and system health validation test scripts.

## Getting Started
To bootstrap the local or target environment:

### Linux/macOS
```bash
./bootstrap/bootstrap.sh
```

### Windows (PowerShell)
```powershell
.\bootstrap\bootstrap.ps1
```

## Architectural Conventions
Please refer to the rules defined in `AGENTS.md` and the skill files under `.ai/skills/` before attempting to modify configurations or introduce new resources.