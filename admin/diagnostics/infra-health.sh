#!/usr/bin/env bash
set -e

echo "=========================================="
echo "    INFRASTRUCTURE HEALTH DIAGNOSTIC"
echo "=========================================="
echo ""

NAMESPACE="aiaad-infra"
PLATFORM_NAMESPACE="aiaad-platform"

echo "1. Namespaces Check"
for ns in $NAMESPACE $PLATFORM_NAMESPACE; do
  if kubectl get ns $ns >/dev/null 2>&1; then
    echo "[OK] Namespace $ns exists"
  else
    echo "[ERROR] Namespace $ns missing"
  fi
done
echo ""

echo "2. Internal Services Readiness & Restarts (Postgres, Temporal, Kafka)"
kubectl get pods -n $NAMESPACE -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,STATUS:.status.phase"
echo ""

echo "3. Persistence (PVCs)"
kubectl get pvc -n $NAMESPACE -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage" 2>/dev/null || echo "No PVCs found."
echo ""

echo "4. Kafka Availability"
if kubectl exec -n $NAMESPACE aiaad-kafka-0 -c kafka -- kafka-broker-api-versions.sh --bootstrap-server localhost:9092 >/dev/null 2>&1; then
  echo "[OK] Kafka broker is responding."
else
  echo "[WARNING] Kafka broker check failed (or pod missing)."
fi
echo ""

echo "5. External Dependency Reachability"
TEST_POD="infra-health-curl-$$"
kubectl run $TEST_POD -n $PLATFORM_NAMESPACE --image=curlimages/curl --restart=Never -- sleep 60 >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready pod/$TEST_POD -n $PLATFORM_NAMESPACE --timeout=30s >/dev/null 2>&1 || true

endpoints=(
  "https://dev.azure.com"
  "https://graph.microsoft.com"
  "https://neo4j.com"
  "https://google.com"
)

for ep in "${endpoints[@]}"; do
  if kubectl exec -n $PLATFORM_NAMESPACE $TEST_POD -- curl -s --connect-timeout 5 -I "$ep" >/dev/null 2>&1; then
    echo "[OK] Reachable: $ep"
  else
    echo "[FAIL] Unreachable: $ep"
  fi
done

kubectl delete pod $TEST_POD -n $PLATFORM_NAMESPACE --ignore-not-found >/dev/null 2>&1
echo ""
echo "Diagnostic complete."
