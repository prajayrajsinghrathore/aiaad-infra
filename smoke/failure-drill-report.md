# Infrastructure Failure Drills Report

**Execution Date:** 2026-08-11
**Target Context:** aiaad-infra / aiaad-platform namespaces

## 1. PostgreSQL Pod Restart Drill
- **Action:** Executed `kubectl delete pod aiaad-postgres-postgresql-0 -n aiaad-infra`
- **Observed Behavior:** The StatefulSet controller detected the pod deletion and immediately re-provisioned a new pod.
- **Recovery/Persistence:** The new pod successfully attached to the existing `data-aiaad-postgres-postgresql-0` PersistentVolumeClaim (PVC). Data persisted across the restart with zero loss.
- **Degradation Impact:** Very brief connection drops (seconds) during pod initialization.
- **Fix/Action Items:** No fixes required. Behavior is as expected for a single-node StatefulSet.

## 2. Kafka Broker Restart Drill
- **Action:** Executed `kubectl delete pod aiaad-kafka-controller-0 -n aiaad-infra`
- **Observed Behavior:** The KRaft single-node pod terminated and was recreated by the StatefulSet controller.
- **Recovery/Persistence:** Re-bound to the existing `data-aiaad-kafka-controller-0` PVC. Topics and lag data survived the restart.
- **Degradation Impact:** While restarting, publishers/consumers experienced connection timeouts. This outage is clearly identified as a degradation period for async messaging; KEDA Kafka-lag triggers paused until the broker returned.
- **Fix/Action Items:** Since this is a single-node KRaft instance (per architecture decisions), downtime is expected during restarts. For production environments requiring higher availability, Kafka should be deployed with `replicaCount: 3` and Min ISR of 2.

## 3. Temporal Worker & Server Restart Drill
- **Action:** Executed `kubectl rollout restart deploy aiaad-temporal-frontend -n aiaad-infra` and `kubectl rollout restart deploy aiaad-temporal-worker -n aiaad-infra`.
- **Observed Behavior:** Deployments performed a rolling update.
- **Recovery/Persistence:** Because Temporal's state is persisted in the backend PostgreSQL database, no running workflow history was lost. Temporal components gracefully resumed execution of active workflows upon restarting and reconnecting to the database.
- **Degradation Impact:** None/Minimal due to Kubernetes rolling updates and Temporal's robust retry/persistence design.
- **Fix/Action Items:** None required. System behaves robustly under stateless component failure.

## 4. Neo4j/External Dependency Connectivity Failure Drill (Simulated)
- **Action:** Simulated external dependency blocking for Neo4j Aura (`0112d4e4.databases.neo4j.io`) and Entra endpoints via invalid network resolution.
- **Observed Behavior:** Diagnostic probes and external connectivity checks return actionable errors immediately (`[BLOCKED] - Network unreachable or DNS resolution failed`).
- **Degradation Impact:** Application operations dependent on these services are correctly isolated. The infrastructure layer surfaces the failure cleanly without crashing the broader mesh or internal persistence layers.
- **Fix/Action Items:** Ensure platform application services utilize appropriate retry mechanisms and Dead Letter Queues (DLQs) for events when these mandatory external APIs are degraded.
