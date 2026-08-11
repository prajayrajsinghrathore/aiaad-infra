#!/usr/bin/env bash
# verify-prerequisites.sh - check tool availability, configurations, and cluster connectivity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Checking required CLI tools..."
for tool in kubectl helm git; do
    if ! command -v "$tool" &> /dev/null; then
        echo "ERROR: Required tool '$tool' is not installed." >&2
        exit 1
    fi
    echo "  - $tool: found"
done

# 1. Parse configuration files
envFile="${REPO_ROOT}/environments/hackathon/environment.yaml"
storageFile="${REPO_ROOT}/environments/hackathon/storage-values.yaml"

if [ ! -f "$envFile" ]; then
    echo "ERROR: Missing environment.yaml at $envFile" >&2
    exit 1
fi

targetContext=$(grep -E '^\s*targetContext:' "$envFile" | awk -F '"' '{print $2}' || true)
if [ -z "$targetContext" ]; then
    targetContext=$(grep -E '^\s*targetContext:' "$envFile" | awk '{print $2}' || true)
fi

if [ -z "$targetContext" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: kubernetes.targetContext is not set in environments/hackathon/environment.yaml"
    exit 1
fi

# 2. Verify current kubectl context matches targetContext
echo "Verifying target context..."
currentContext=$(kubectl config current-context 2>/dev/null || echo "")
if [ "$currentContext" != "$targetContext" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Current context '$currentContext' does not match targetContext '$targetContext' defined in environment.yaml"
    exit 1
fi

# 3. Verify cluster connectivity
echo "Checking cluster connectivity..."
if ! kubectl cluster-info &>/dev/null; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot connect to Kubernetes cluster using context '$targetContext'."
    exit 1
fi

# 4. Check for existing Gateway/Istio installation
echo "Checking for existing Istio installation..."
gatewayValuesFile="${REPO_ROOT}/environments/hackathon/gateway-values.yaml"
gwName=$(grep -E '^\s*name:' "$gatewayValuesFile" | awk -F '"' '{print $2}' || true)
gwNamespace=$(grep -E '^\s*namespace:' "$gatewayValuesFile" | awk -F '"' '{print $2}' || true)

if [ -z "$gwName" ]; then gwName=$(grep -E '^\s*name:' "$gatewayValuesFile" | awk '{print $2}' || true); fi
if [ -z "$gwNamespace" ]; then gwNamespace=$(grep -E '^\s*namespace:' "$gatewayValuesFile" | awk '{print $2}' || true); fi

if kubectl get gateway -n "$gwNamespace" "$gwName" &>/dev/null; then
    echo "  - Existing Gateway $gwNamespace/$gwName found."
else
    echo "WARNING: Could not find Gateway $gwNamespace/$gwName in the cluster."
fi

# 5. Check storage class configuration
echo "Checking storage class availability..."
storageClass=$(grep -E '^\s*storageClass:' "$storageFile" | awk -F '"' '{print $2}' || true)
if [ -z "$storageClass" ]; then
    storageClass=$(grep -E '^\s*storageClass:' "$storageFile" | awk '{print $2}' || true)
fi

if kubectl get storageclass "$storageClass" &>/dev/null; then
    echo "  - StorageClass '$storageClass' verified in cluster."
else
    echo "WARNING: StorageClass '$storageClass' is not found in the active cluster context."
fi

echo "All prerequisites checks completed."
