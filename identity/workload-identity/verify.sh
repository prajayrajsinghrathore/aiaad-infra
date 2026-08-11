#!/usr/bin/env bash
# identity/workload-identity/verify.sh - Validate workload identity configurations and environment variables injection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SA_Name="identity-test-sa"
Pod_Name="identity-test-pod"
Namespace="aiaad-infra"

# Dummy/Test client/tenant IDs for local validation (non-secret values)
TestClientId="11111111-1111-1111-1111-111111111111"
TestTenantId="22222222-2222-2222-2222-222222222222"

echo "Creating ServiceAccount with test Workload Identity annotations..."
sed -e "s/\${SERVICE_ACCOUNT_NAME}/${SA_Name}/g" \
    -e "s/\${NAMESPACE}/${Namespace}/g" \
    -e "s/\${AZURE_CLIENT_ID}/${TestClientId}/g" \
    -e "s/\${AZURE_TENANT_ID}/${TestTenantId}/g" \
    "${SCRIPT_DIR}/templates/serviceaccount.yaml" | kubectl apply -f -

echo "Deploying identity test Pod..."
kubectl apply -f "${SCRIPT_DIR}/templates/test-pod.yaml"

echo "Waiting for Pod to start..."
timeout=30
while [ $timeout -gt 0 ]; do
    status=$(kubectl get pod -n "$Namespace" "$Pod_Name" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Pending")
    if [ "$status" = "Running" ]; then
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

status=$(kubectl get pod -n "$Namespace" "$Pod_Name" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
if [ "$status" != "Running" ]; then
    echo "WARNING: Pod did not reach Running state within timeout."
fi

echo "Checking injected environment variables..."
if envVars=$(kubectl exec -n "$Namespace" "$Pod_Name" -- env 2>/dev/null); then
    if echo "$envVars" | grep -q "AZURE_CLIENT_ID" && \
       echo "$envVars" | grep -q "AZURE_TENANT_ID" && \
       echo "$envVars" | grep -q "AZURE_FEDERATED_TOKEN_FILE"; then
        echo "SUCCESS: Workload Identity variables successfully injected into test pod!"
    else
        echo "WARNING: Workload Identity environment variables were NOT injected. Workload Identity is likely not enabled in this cluster."
    fi
else
    echo "WARNING: Could not query pod environment variables."
fi

echo "Cleaning up test resources..."
kubectl delete pod -n "$Namespace" "$Pod_Name" --ignore-not-found=true
kubectl delete serviceaccount -n "$Namespace" "$SA_Name" --ignore-not-found=true
echo "Cleanup done."
