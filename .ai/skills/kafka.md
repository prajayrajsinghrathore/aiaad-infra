# Kafka
- Self-host one KRaft node with combined broker/controller role.
- Replication factor 1; non-production trial only.
- Topics: platform.domain.events, platform.integration.events, platform.dlq.
- Kafka is non-critical: application canonical DB writes must not depend on broker availability.
- Infra provides broker, topics and smoke/failure diagnostics; application outbox/consumer code belongs in aiaad-platform.
- Do not introduce ZooKeeper.
- Pin chart/image versions.
