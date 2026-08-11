# Platform Handoff Contract (aiaad-platform)

This document serves as the final non-secret infrastructure handoff contract between the `aiaad-infra` layer and the `aiaad-platform` application developers. 

It defines the exact DNS names, configuration references, and architectural expectations required to deploy applications into the target AKS environment. **Never commit actual credentials, connection strings, or PATs into your application code or Git repositories.**

---

## 1. Kubernetes Topography

All application workloads must be deployed exclusively to the designated platform namespace.
- **Platform Namespace:** `aiaad-platform`
- **Infra Namespace:** `aiaad-infra` (Read-only for applications; do not deploy business logic here)

---

## 2. Internal Stateful Services

The following core infrastructure services are hosted in the `aiaad-infra` namespace. Your applications can reach them securely using the internal cluster DNS.

### 2.1 PostgreSQL (Relational Data & pgvector)
- **Host:** `aiaad-postgres-postgresql.aiaad-infra.svc.cluster.local`
- **Port:** `5432`
- **Database Name:** Usually `postgres` (or as configured by your DB initialization logic)
- **Auth:** Provided dynamically or via securely injected Kubernetes secrets. No plain-text passwords.

### 2.2 Temporal (Workflow Orchestration)
- **Frontend gRPC Address:** `aiaad-temporal-frontend.aiaad-infra.svc.cluster.local:7233`
- **Temporal Namespace:** `default`
- **UI Port-Forward (Admin):** `http://localhost:8080` (requires running the `admin/port-forward/temporal-ui.sh` tool locally; not exposed via public ingress).

### 2.3 Kafka (Event Streaming & Messaging)
- **Bootstrap Servers:** `aiaad-kafka.aiaad-infra.svc.cluster.local:9092`
- **Standard Topics:** 
  - `platform.domain.events`
  - `platform.integration.events`
  - `platform.dlq`
- *Note:* Kafka is running in a single-node KRaft configuration for non-production environments. Expect brief connection drops during pod restarts.

### 2.4 Object Storage (Optional / Degraded)
- **Status:** **OPTIONAL** (may not be deployed in all environments)
- **Local Provider (MinIO):** `http://aiaad-minio.aiaad-infra.svc.cluster.local:9000`
- **Production Provider:** Deferred to Azure Storage Account (blob).

---

## 3. Network Egress & External Boundaries

Egress traffic is natively permitted (`ALLOW_ANY`) within the cluster network configuration. External service configurations must be injected cleanly.

### 3.1 Neo4j Aura (External Graph)
- **Endpoint Key:** Defined by `neo4jUri` in `environments/*/environment.yaml`
- **Credentials:** Bound to the `aiaad-neo4j-credentials` Kubernetes secret (`NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`). Do not hardcode URI in the app.

### 3.2 OpenAI API
- **Endpoint Key:** Defined by `openAiApiEndpoint` in `environments/*/environment.yaml`
- **Auth:** Connection is authenticated via the OpenAI service account key, mapped to the Kubernetes secret `openai-service-account` from Azure Key Vault. Ensure proper secret mapping is established for pods.

### 3.3 Azure DevOps (ADO)
- **Auth:** Bound to the `aiaad-ado-credentials` Kubernetes secret (`ADO_PAT`). 

### 3.4 SharePoint & Microsoft Graph
- **Endpoint Key:** Defined by `sharePointTenantUrl` in `environments/*/environment.yaml`.

---

## 4. Workload Scaling (KEDA)
If your workers scale on Kafka lag, do **NOT** use default scaling limits.
- **Requirement:** You must set explicit `minReplicaCount` and `maxReplicaCount` to avoid overwhelming OpenAI API quotas and incurring cascading HTTP 429 errors.
- **Templates:** See `keda/templates/kafka-scaledobject.template.yaml`.

---

## 5. Operations & Troubleshooting
- **Smoke Tests:** Executing `smoke/run-all.ps1` will validate platform connectivity, network egress, and service health.
- **Admin Tools:** Port-forwarding tools for pgAdmin, Temporal UI, and Kafka UI are provided in `admin/port-forward/`. These must never be exposed publicly.
