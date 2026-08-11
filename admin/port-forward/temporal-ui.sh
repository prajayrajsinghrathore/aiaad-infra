#!/usr/bin/env bash
set -eo pipefail

echo "Port-forwarding Temporal UI..."
echo "Access the Temporal UI at http://localhost:8080"
echo "Press Ctrl+C to stop."

kubectl port-forward svc/aiaad-temporal-web 8080:8080 -n aiaad-infra
