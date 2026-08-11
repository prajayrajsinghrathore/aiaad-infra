# KEDA
- KEDA is optional/useful for selected worker scaling.
- Infra may provide inactive templates before app workers exist.
- Activate only with an owning service, a real scaler source and explicit min/max replicas.
- Kafka-lag scaling must not indirectly overwhelm Azure AI Foundry quotas.
- Do not use KEDA merely because it is installed.
