# PostgreSQL
- Self-hosted in aiaad-infra, one physical cluster for hackathon.
- Required DBs: aiaad, temporal, temporal_visibility.
- Enable pgvector only in aiaad unless a concrete need says otherwise.
- Service-owned business schemas/migrations live in aiaad-platform, not infra.
- Infra may bootstrap databases, extensions and database roles/grants.
- Cross-service SQL access is forbidden even though the physical DB is shared.
- Use persistent storage and verify pod-restart persistence.
- Pin the selected Helm chart/image version in repo values; do not silently upgrade.
