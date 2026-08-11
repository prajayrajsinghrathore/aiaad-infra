#!/usr/bin/env bash
set -e

echo "Running Infrastructure Smoke Suite..."
JSON_REPORT="{"
fail_count=0

function check_status() {
  local component=$1
  local status=$2
  local reason=$3

  if [ "$status" == "FAIL" ]; then
    fail_count=$((fail_count+1))
  fi

  echo "[$status] $component: $reason"
  JSON_REPORT+="\"$component\": {\"status\": \"$status\", \"reason\": \"$reason\"},"
}

# 1. Namespaces
if kubectl get ns aiaad-infra >/dev/null 2>&1 && kubectl get ns aiaad-platform >/dev/null 2>&1; then
  check_status "Namespaces" "PASS" "Required namespaces exist."
else
  check_status "Namespaces" "FAIL" "Missing aiaad-infra or aiaad-platform."
fi

# 2. Postgres
if kubectl get statefulset aiaad-postgres-postgresql -n aiaad-infra >/dev/null 2>&1; then
  ready=$(kubectl get statefulset aiaad-postgres-postgresql -n aiaad-infra -o jsonpath='{.status.readyReplicas}')
  if [ "$ready" == "1" ]; then
    check_status "Postgres" "PASS" "Postgres is ready."
  else
    check_status "Postgres" "FAIL" "Postgres pod not ready."
  fi
else
  check_status "Postgres" "FAIL" "Postgres StatefulSet not found."
fi

# 3. Temporal
if kubectl get deploy aiaad-temporal-frontend -n aiaad-infra >/dev/null 2>&1; then
  ready=$(kubectl get deploy aiaad-temporal-frontend -n aiaad-infra -o jsonpath='{.status.readyReplicas}')
  if [[ "$ready" -gt 0 ]]; then
    check_status "Temporal" "PASS" "Temporal frontend is ready."
  else
    check_status "Temporal" "FAIL" "Temporal frontend pod not ready."
  fi
else
  check_status "Temporal" "FAIL" "Temporal deployment not found."
fi

# 4. Kafka
if kubectl get statefulset aiaad-kafka-controller -n aiaad-infra >/dev/null 2>&1; then
  ready=$(kubectl get statefulset aiaad-kafka-controller -n aiaad-infra -o jsonpath='{.status.readyReplicas}')
  if [ "$ready" == "1" ]; then
    check_status "Kafka" "PASS" "Kafka controller is ready."
  else
    check_status "Kafka" "FAIL" "Kafka controller not ready."
  fi
else
  check_status "Kafka" "FAIL" "Kafka StatefulSet not found."
fi

# 5. Object Storage (Minio - Optional)
if kubectl get statefulset aiaad-minio -n aiaad-infra >/dev/null 2>&1 || kubectl get deploy aiaad-minio -n aiaad-infra >/dev/null 2>&1; then
  check_status "ObjectStorage" "PASS" "Minio deployed."
else
  check_status "ObjectStorage" "SKIPPED" "Minio optional component not installed."
fi

# 7. External Connectivity (Neo4j, OpenAI, ADO/Graph)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Neo4j
if "${SCRIPT_DIR}/neo4j-connectivity.sh" >/dev/null 2>&1; then
  check_status "Neo4jConnectivity" "PASS" "Reachable and queried successfully."
else
  check_status "Neo4jConnectivity" "FAIL" "Failed to connect or query."
fi

# OpenAI
if "${SCRIPT_DIR}/openai.sh" >/dev/null 2>&1; then
  check_status "OpenAiConnectivity" "PASS" "Reachable."
else
  check_status "OpenAiConnectivity" "FAIL" "Unreachable."
fi

# ADO & Graph/SharePoint
if "${SCRIPT_DIR}/ado-graph-connectivity.sh" >/dev/null 2>&1; then
  check_status "AdoGraphConnectivity" "PASS" "Reachable."
else
  check_status "AdoGraphConnectivity" "FAIL" "Unreachable."
fi

JSON_REPORT=${JSON_REPORT%?}
JSON_REPORT+="}"

echo ""
echo "--- Machine Readable Report (JSON) ---"
echo $JSON_REPORT | tee smoke-report.json
echo ""
echo ""

if [ $fail_count -eq 0 ]; then
  echo "OVERALL STATUS: READY"
  exit 0
else
  echo "OVERALL STATUS: BLOCKED ($fail_count failures)"
  exit 1
fi
