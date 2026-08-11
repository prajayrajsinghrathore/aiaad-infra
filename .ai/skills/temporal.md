# Temporal
- Temporal OSS self-hosted in aiaad-infra.
- Use PostgreSQL temporal + temporal_visibility.
- Hackathon deployment is intentionally non-HA/small.
- Application Temporal namespace: aiaad-hackathon.
- Temporal UI is admin-only.
- Infra smoke may use a tiny hello/signal workflow, but application workflows belong in aiaad-platform.
- Do not add Elasticsearch/Cassandra unless an explicit requirement is approved.
- Pin chart/image versions and document values.
