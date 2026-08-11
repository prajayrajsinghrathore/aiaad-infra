#!/usr/bin/env bash
set -e

echo "Running Azure AI Foundry Connectivity & Auth Smoke Test..."

ENV_FILE="$(dirname "$0")/../environments/hackathon/environment.yaml"
if [ ! -f "$ENV_FILE" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $ENV_FILE"
    exit 1
fi

# Extract endpoint
ENDPOINT=$(grep "azureAiFoundryEndpoint:" "$ENV_FILE" | awk -F'"' '{print $2}')

if [[ -z "$ENDPOINT" || "$ENDPOINT" == *"placeholder"* ]]; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: Azure AI Foundry endpoint is set to a placeholder ('$ENDPOINT'). Update environments/hackathon/environment.yaml with the real endpoint before running this test."
  exit 1
fi

echo "Endpoint: $ENDPOINT"
echo "Testing network connectivity and TLS..."

TEST_POD="foundry-smoke-$$"
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

echo ""
echo "Note: Full authentication via Workload Identity (federated credentials) must be validated by the application SDK (e.g. DefaultAzureCredential). This script validates the network path is open."
echo "STATUS=READY"
exit 0
