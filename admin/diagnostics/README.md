# Infrastructure Observability and Health

## Dashboard References

This project leverages the native observability tools available within Azure Kubernetes Service (AKS). We do not deploy a competing monitoring stack (e.g., custom Prometheus/Grafana) to avoid unnecessary overhead.

*   **Azure Monitor for Containers / Container Insights:** All standard metrics (CPU, Memory, Node health, Pod readiness) are automatically scraped and shipped to the connected Log Analytics Workspace.
*   **Istio Mesh Observability:** Istio sidecars (when injected) automatically export telemetry to Azure Monitor or an integrated Application Insights workspace depending on the cluster-wide setup.

## Metrics Scraping Configuration

For custom metrics (e.g., Postgres, Kafka, Temporal), standard prometheus scraping annotations can be added to the deployments/statefulsets.
The Azure Monitor agent (`ama-metrics`) automatically discovers pods with these annotations:
```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "<metrics-port>"
    prometheus.io/path: "/metrics"
```
Ensure that project-scoped helm charts expose these metrics on standard ports if further observability is required.

## Health Diagnostic Scripts

To quickly assert the state of all dependencies from an operator point of view, use the provided diagnostic scripts:
*   **Bash:** `admin/diagnostics/infra-health.sh`
*   **PowerShell:** `admin/diagnostics/infra-health.ps1`

These scripts will run checks on:
1.  **Namespaces Check:** Ensures `aiaad-infra` and `aiaad-platform` are available.
2.  **Internal Services Readiness:** Analyzes Postgres, Temporal, and Kafka pod readiness, status, and restart counts.
3.  **Persistence:** Validates PersistentVolumeClaims (PVCs) for stateful data integrity.
4.  **Kafka Availability:** Verifies internal cluster reachability of Kafka brokers.
5.  **External Reachability:** Executes a curl probe from the platform namespace to confirm Azure DevOps, Microsoft Graph, and Neo4j connectivity.
