#!/usr/bin/env bash
set -e

echo "Running ADO & Graph/SharePoint Network Connectivity Diagnostic..."

ENV_FILE="$(dirname "$0")/../environments/hackathon/environment.yaml"
if [ ! -f "$ENV_FILE" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $ENV_FILE"
    exit 1
fi

SP_ENDPOINT=$(grep "sharePointTenantUrl:" "$ENV_FILE" | awk -F'"' '{print $2}')

if [[ -z "$SP_ENDPOINT" || "$SP_ENDPOINT" == *"placeholder"* ]]; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: SharePoint endpoint is set to a placeholder ('$SP_ENDPOINT'). Update environments/hackathon/environment.yaml with the real tenant URL before running this test."
  exit 1
fi

TEST_POD="ado-graph-smoke-$$"
kubectl run $TEST_POD -n aiaad-platform --image=curlimages/curl --restart=Never -- sleep 60 >/dev/null 2>&1
kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=30s >/dev/null 2>&1 || true

FAILURES=0

function verify_endpoint() {
  local name=$1
  local url=$2
  
  echo -n "Testing $name ($url)... "
  if kubectl exec -n aiaad-platform $TEST_POD -- curl -s --connect-timeout 5 -I "$url" >/dev/null 2>&1; then
    echo "[READY]"
  else
    echo "[BLOCKED] - Network unreachable or DNS resolution failed."
    FAILURES=$((FAILURES+1))
  fi
}

verify_endpoint "Azure DevOps" "https://dev.azure.com"
verify_endpoint "Microsoft Graph" "https://graph.microsoft.com"
verify_endpoint "Entra ID (Login)" "https://login.microsoftonline.com"
verify_endpoint "SharePoint (Root)" "$SP_ENDPOINT"

echo -n "Testing Authenticated ADO access (PAT)... "
if kubectl get secret aiaad-ado-credentials -n aiaad-platform >/dev/null 2>&1; then
  if kubectl exec -n aiaad-platform $TEST_POD -- sh -c 'ADO_PAT=$(kubectl get secret aiaad-ado-credentials -n aiaad-platform -o jsonpath="{.data.ADO_PAT}" | base64 -d 2>/dev/null); curl -s --connect-timeout 5 -w "%{http_code}" -u ":$ADO_PAT" https://dev.azure.com | grep -E "^(2|3|4)" >/dev/null' >/dev/null 2>&1; then
     echo "[READY]"
  else
     echo "[BLOCKED] Authentication failed or endpoint unreachable with provided PAT."
  fi
else
  echo "[SKIPPED] No 'aiaad-ado-credentials' secret provided."
fi

kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1

if [ $FAILURES -eq 0 ]; then
  echo "OVERALL STATUS: READY"
  exit 0
else
  echo "OVERALL STATUS: BLOCKED ($FAILURES failures)"
  exit 1
fi
