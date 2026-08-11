#!/usr/bin/env bash
set -eo pipefail

echo "Port-forwarding pgAdmin..."
echo "Access pgAdmin at http://localhost:8081"
echo "Press Ctrl+C to stop."

# Note: pgAdmin is an optional component. If not installed, this will fail.
kubectl port-forward svc/aiaad-pgadmin 8081:80 -n aiaad-infra
