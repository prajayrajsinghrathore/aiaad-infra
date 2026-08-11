#!/usr/bin/env bash
set -e

echo "Running Azure Storage Account & Workload Identity connectivity test..."

ENV_FILE="$(dirname "$0")/../environments/hackathon/environment.yaml"
if [ ! -f "$ENV_FILE" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot find environment.yaml"
    exit 1
fi

STORAGE_ACCOUNT=$(grep "storageAccountName:" "$ENV_FILE" | awk -F'"' '{print $2}')
CLIENT_ID=$(grep "workloadIdentityClientId:" "$ENV_FILE" | awk -F'"' '{print $2}')
TENANT_ID=$(grep "tenantId:" "$ENV_FILE" | awk -F'"' '{print $2}')

if [[ -z "$STORAGE_ACCOUNT" || -z "$CLIENT_ID" || -z "$TENANT_ID" ]]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Missing storage account name, Client ID, or Tenant ID in environment.yaml"
    exit 1
fi

TEST_POD="storage-smoke-$$"
echo "Launching test pod in aiaad-platform namespace..."

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: $TEST_POD
  namespace: aiaad-platform
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: aiaad-platform-sa
  containers:
  - name: azure-cli
    image: mcr.microsoft.com/azure-cli:latest
    command: ["sleep", "120"]
EOF

kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=60s >/dev/null 2>&1 || true

echo "Authenticating via Workload Identity and listing containers..."
if kubectl exec -n aiaad-platform $TEST_POD -- sh -c "
  az login --federated-token \"\$(cat \$AZURE_FEDERATED_TOKEN_FILE)\" --service-principal -u \"\$AZURE_CLIENT_ID\" -t \"\$AZURE_TENANT_ID\" --allow-no-subscriptions >/dev/null 2>&1
  az storage container list --account-name $STORAGE_ACCOUNT --auth-mode login -o table
" 2>/dev/null; then
    echo "[READY] Successfully authenticated and retrieved container list!"
    STATUS="READY"
else
    echo "[BLOCKED] Failed to authenticate or retrieve container list from storage account $STORAGE_ACCOUNT."
    STATUS="BLOCKED"
fi

kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1
if [ "$STATUS" == "READY" ]; then
    exit 0
else
    exit 1
fi
