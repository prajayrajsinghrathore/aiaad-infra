#!/usr/bin/env bash
set -e

echo "Running OpenAI API Connectivity Smoke Test..."

ENV_FILE="$(dirname "$0")/../environments/hackathon/environment.yaml"
if [ ! -f "$ENV_FILE" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $ENV_FILE"
    exit 1
fi

ENDPOINT=$(grep "openAiApiEndpoint:" "$ENV_FILE" | awk -F'"' '{print $2}')

if [[ -z "$ENDPOINT" ]]; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: OpenAI API endpoint is not set. Update environments/hackathon/environment.yaml."
  exit 1
fi

echo "Endpoint: $ENDPOINT"
echo "Testing network connectivity and TLS..."

TEST_POD="openai-smoke-$$"
kubectl run $TEST_POD -n aiaad-platform --image=curlimages/curl --restart=Never -- sleep 60 >/dev/null 2>&1
kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=30s >/dev/null 2>&1 || true

if kubectl exec -n aiaad-platform $TEST_POD -- curl -s --connect-timeout 5 -I "$ENDPOINT" >/dev/null 2>&1; then
    echo "[READY] Network reachable."
else
    echo "[BLOCKED] Network unreachable or DNS resolution failed for $ENDPOINT."
    kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1
    exit 1
fi

kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1

echo "STATUS=READY"
exit 0
