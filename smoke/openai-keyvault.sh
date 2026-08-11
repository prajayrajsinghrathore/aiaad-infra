#!/usr/bin/env bash
set -e

echo "Running OpenAI Key Vault Secret Sync Smoke Test..."

TEST_POD="keyvault-smoke-$$"
echo "Launching test pod to mount SecretProviderClass..."

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
  - name: test-container
    image: mcr.microsoft.com/azure-cli:latest
    command: ["sleep", "60"]
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "aiaad-keyvault-spc"
EOF

echo "Waiting for pod to start..."
kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=60s >/dev/null 2>&1 || true

echo "Checking if Kubernetes secret openai-service-account was created..."
if kubectl get secret openai-service-account -n aiaad-platform >/dev/null 2>&1; then
    echo "[READY] Kubernetes secret 'openai-service-account' successfully synced from Key Vault!"
    STATUS="READY"
else
    echo "[BLOCKED] Kubernetes secret 'openai-service-account' was not created. Check CSI driver pod logs."
    STATUS="BLOCKED"
fi

kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1
if [ "$STATUS" == "READY" ]; then
    exit 0
else
    exit 1
fi
