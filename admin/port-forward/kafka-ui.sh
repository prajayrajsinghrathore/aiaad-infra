#!/usr/bin/env bash
set -eo pipefail

echo "Port-forwarding Kafka UI (Kowl/Redpanda Console)..."
echo "Access Kafka UI at http://localhost:8082"
echo "Press Ctrl+C to stop."

# Note: Kafka UI is an optional component. If not installed, this will fail.
kubectl port-forward svc/aiaad-kowl 8082:8080 -n aiaad-infra
