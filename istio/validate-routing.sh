#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

VALUES_FILE="${REPO_ROOT}/environments/hackathon/gateway-values.yaml"
TEMPLATE_FILE="${SCRIPT_DIR}/virtualservice.template.yaml"

if [ ! -f "$VALUES_FILE" ]; then
    echo "ERROR: Cannot find gateway values file at $VALUES_FILE" >&2
    exit 1
fi

GATEWAY_NAME=$(grep -E '^\s*name:' "$VALUES_FILE" | awk -F '"' '{print $2}')
GATEWAY_NAMESPACE=$(grep -E '^\s*namespace:' "$VALUES_FILE" | awk -F '"' '{print $2}')
GATEWAY_HOST=$(grep -E '^\s*host:' "$VALUES_FILE" | awk -F '"' '{print $2}')

export GATEWAY_NAME GATEWAY_NAMESPACE GATEWAY_HOST

if command -v envsubst &> /dev/null; then
  envsubst < "$TEMPLATE_FILE" > "${SCRIPT_DIR}/virtualservice.yaml"
else
  sed -e "s/\${GATEWAY_NAME}/${GATEWAY_NAME}/g" \
      -e "s/\${GATEWAY_NAMESPACE}/${GATEWAY_NAMESPACE}/g" \
      -e "s/\${GATEWAY_HOST}/${GATEWAY_HOST}/g" \
      "$TEMPLATE_FILE" > "${SCRIPT_DIR}/virtualservice.yaml"
fi

echo "Rendered VirtualService manifest:"
cat "${SCRIPT_DIR}/virtualservice.yaml"

echo ""
echo "Running validation (dry-run) against cluster..."
kubectl apply -f "${SCRIPT_DIR}/virtualservice.yaml" --dry-run=client

echo "Validation successful."
