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

## 3. Istio Ingress & Network Egress

The cluster uses an Istio service mesh to govern ingress (inbound) and egress (outbound) traffic.

### 3.1 Ingress Routing
Do **NOT** deploy new Gateway resources. Use the centralized, approved gateway:
- **Gateway Reference:** `istio-system/aiaad-gateway`
- **Application Implementation:** Deploy `VirtualService` manifests in the `aiaad-platform` namespace that map specific HTTP routes (e.g. `prefix: /api`) to your target services. A template is available at `istio/virtualservice.template.yaml`.

### 3.2 Egress & External Boundaries
Egress traffic is natively permitted (`ALLOW_ANY`). However, any external service configuration must be injected cleanly.

#### Neo4j Aura (External Graph)
- **Endpoint Key:** Defined by `neo4jUri` in `environments/*/environment.yaml`
- **Credentials:** Bound to the `aiaad-neo4j-credentials` Kubernetes secret (`NEO4J_URI`, `NEO4J_USERNAME`, `NEO4J_PASSWORD`). Do not hardcode URI in the app.

#### Azure AI Foundry (OpenAI)
- **Endpoint Key:** Defined by `azureAiFoundryEndpoint` in `environments/*/environment.yaml`
- **Auth:** Must use **Azure Workload Identity** (federated tokens). Static API keys are explicitly banned. Ensure your Azure Identity SDK (e.g. `DefaultAzureCredential`) is configured to leverage the managed identity.

#### Azure DevOps (ADO)
- **Auth:** Bound to the `aiaad-ado-credentials` Kubernetes secret (`ADO_PAT`). 

#### SharePoint & Microsoft Graph
- **Endpoint Key:** Defined by `sharePointTenantUrl` in `environments/*/environment.yaml`.

---

## 4. Workload Scaling (KEDA)
If your workers scale on Kafka lag, do **NOT** use default scaling limits.
- **Requirement:** You must set explicit `minReplicaCount` and `maxReplicaCount` to avoid overwhelming Azure AI Foundry quotas and incurring cascading HTTP 429 errors.
- **Templates:** See `keda/templates/kafka-scaledobject.template.yaml`.

---

## 5. Operations & Troubleshooting
- **Smoke Tests:** Executing `smoke/run-all.ps1` will validate platform connectivity, network egress, and service health.
- **Admin Tools:** Port-forwarding tools for pgAdmin, Temporal UI, and Kafka UI are provided in `admin/port-forward/`. These must never be exposed publicly.
