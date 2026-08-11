#!/usr/bin/env bash
set -eo pipefail

echo "Port-forwarding RedisInsight..."
echo "Access RedisInsight at http://localhost:8083"
echo "Press Ctrl+C to stop."

# Note: RedisInsight is an optional component. If not installed, this will fail.
kubectl port-forward svc/aiaad-redisinsight 8083:80 -n aiaad-infra
