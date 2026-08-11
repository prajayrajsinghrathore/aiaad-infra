# Naming
Namespaces: aiaad-infra, aiaad-platform.
Helm releases: aiaad-postgres, aiaad-temporal, aiaad-kafka, optional aiaad-redis/aiaad-minio/aiaad-pgadmin/aiaad-kafka-ui/aiaad-redisinsight.
Application database: aiaad. Temporal databases: temporal, temporal_visibility.
Temporal namespace: aiaad-hackathon.
Kafka topics: platform.domain.events, platform.integration.events, platform.dlq.
Use lowercase kebab-case for Kubernetes resources and Helm releases.
Environment values live under environments/hackathon; do not hard-code target-specific gateway/host/UAMI IDs in reusable templates.
