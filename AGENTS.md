# aiaad-infra Agent Instructions

## Before doing any work

1. Read this file completely.
2. Read only the `.ai/skills/*.md` files specified by the active INF work-package prompt.
3. Inspect the existing repository before creating or moving files.
4. Inspect the target AKS environment when the work package depends on cluster state.
5. Verify prerequisite INF work packages are actually usable.

If a required value or architectural decision cannot be discovered from:
- the repository,
- the specified skill files,
- the target environment, or
- the work-package prompt,

STOP and return `STATUS=BLOCKED`.

Do not invent or assume:
- Istio Gateway names
- host names
- UAMI/client IDs
- storage classes
- chart versions
- network/security policy
- secret-management conventions


## Non-negotiable architecture

- Repository is `aiaad-infra`.
- Application source belongs in `aiaad-platform`.
- Project namespaces are exactly:
  - `aiaad-infra`
  - `aiaad-platform`
- Reuse the existing AKS Istio installation and approved Gateway.
- Do not install another ingress controller or Gateway.
- PostgreSQL, Temporal OSS and Kafka are self-hosted in `aiaad-infra`.
- Neo4j Aura and Azure AI Foundry are external dependencies.
- Kafka is single-node KRaft and non-critical.
- Redis is optional.
- Prefer Azure Blob in AKS.
- Follow existing UAMI/federated workload-identity and ESI/CSO conventions.
- Never commit or print secrets.


## Common execution protocol

### Before implementation

- Read the skill files named by the work-package prompt.
- Inspect current repo status/tree.
- Inspect relevant AKS resources.
- Verify prerequisite INF work packages.
- Resolve values from existing configuration/environment.
- If a required fact is missing, return `BLOCKED`. Do not guess.

### During implementation

- Change only the active INF work-package scope.
- Extend existing files rather than creating competing alternatives.
- Do not introduce new infrastructure technologies.
- Do not weaken Istio, mTLS, egress or identity controls.
- Do not expose admin services publicly.
- Keep reusable values non-secret.
- Keep environment-specific values under the agreed environment configuration.
- Do not add application/domain code to this repo.

### Before completion

- Render/lint Helm and manifests where applicable.
- Run the work-package verification.
- Run relevant smoke tests.
- Demonstrate the exit criterion.
- Do not claim `DONE` for anything that was not actually verified.


## Required completion response

Return:

STATUS

FILES CHANGED

COMMANDS/TESTS RUN

EXIT-CRITERION EVIDENCE

BLOCKERS/DEVIATIONS