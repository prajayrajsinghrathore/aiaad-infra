#!/usr/bin/env bash
# aiaad-infra bootstrap entrypoint for Linux/macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "========================================="
echo "  aiaad-infra Bootstrap Orchestration    "
echo "========================================="

echo ""
echo "[STEP 1/7] Running prerequisite validation..."
"${SCRIPT_DIR}/verify-prerequisites.sh"

echo ""
echo "[STEP 2/7] Applying Kubernetes Namespaces..."
kubectl apply -f "${REPO_ROOT}/namespaces/aiaad-infra.yaml"
kubectl apply -f "${REPO_ROOT}/namespaces/aiaad-platform.yaml"
kubectl apply -f "${REPO_ROOT}/namespaces/aiaad-platform-sa.yaml"

echo ""
echo "[STEP 3/7] Deploying Required Component: PostgreSQL..."
if [ -f "${SCRIPT_DIR}/deploy-postgres.sh" ]; then
    "${SCRIPT_DIR}/deploy-postgres.sh"
else
    pwsh -File "${SCRIPT_DIR}/deploy-postgres.ps1"
fi

echo ""
echo "[STEP 4/7] Deploying Required Component: Kafka..."
if [ -f "${SCRIPT_DIR}/deploy-kafka.sh" ]; then
    "${SCRIPT_DIR}/deploy-kafka.sh"
else
    pwsh -File "${SCRIPT_DIR}/deploy-kafka.ps1"
fi

echo ""
echo "[STEP 5/7] Deploying Required Component: Temporal..."
if [ -f "${SCRIPT_DIR}/deploy-temporal.sh" ]; then
    "${SCRIPT_DIR}/deploy-temporal.sh"
else
    pwsh -File "${SCRIPT_DIR}/deploy-temporal.ps1"
fi

echo ""
echo "[STEP 6/7] Deploying Optional Component: Minio..."
echo "Skipping optional Minio deployment by default. Run deploy-minio.ps1 manually if required."

echo ""
echo "[STEP 7/7] Verifying Infrastructure Health..."
if [ -f "${REPO_ROOT}/admin/diagnostics/infra-health.sh" ]; then
    "${REPO_ROOT}/admin/diagnostics/infra-health.sh"
fi

echo ""
echo "=== Bootstrap sequence completed successfully ==="
