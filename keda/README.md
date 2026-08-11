# KEDA Scaling Templates

This directory contains reusable KEDA `ScaledObject` templates for dynamically scaling application workers based on Kafka consumer lag.

## ⚠️ CAUTION: LLM-Quota and External Dependency Limits
Kafka-lag-driven scaling can rapidly provision new worker pods when a backlog of messages accumulates.
If these workers invoke external dependencies (such as **Azure AI Foundry / OpenAI API limits**, Neo4j Aura limits, etc.), sudden scaling can cause quota exhaustion, HTTP 429 Too Many Requests errors, or cascading failures.

**Ownership of `maxReplicaCount`**: The platform team or service owner of the target deployment is strictly responsible for defining safe scaling limits (`maxReplicaCount`). You must align this limit with the smallest bottleneck in your downstream dependencies (e.g., LLM tokens/minute quota).

## Activation Checklist

Do **NOT** activate KEDA ScaledObjects prematurely. You must check the following before applying these templates to the cluster:

- [ ] **Worker Exists**: The target `Deployment` (e.g., in `aiaad-platform`) is actually deployed and functional.
- [ ] **Consumer Group Configured**: The application is configured with the correct Kafka `consumerGroup` mapped in the `ScaledObject`.
- [ ] **Limits Defined**: Explicit `minReplicaCount` and `maxReplicaCount` have been set. Do NOT use default unbound maximums.
- [ ] **Quota Analyzed**: The `maxReplicaCount` has been verified against Azure AI Foundry or other external dependency rate limits.
- [ ] **Idempotent Workers**: The scaled workers are idempotent and can handle concurrent processing of events from the topic safely.
- [ ] **Opt-In Confirmed**: The service owner has explicitly opted in and reviewed the scaling thresholds (`lagThreshold`).

To activate, copy the template from `templates/kafka-scaledobject.template.yaml`, populate the placeholders (`YOUR_WORKER_DEPLOYMENT_NAME`, `YOUR_CONSUMER_GROUP_ID`), and deploy it to the `aiaad-platform` namespace.
