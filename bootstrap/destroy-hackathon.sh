#!/usr/bin/env bash
set -e

DRY_RUN=true
if [ "${1:-}" == "--force" ]; then
    DRY_RUN=false
fi

echo "========================================="
echo "  aiaad-infra Hackathon Teardown Script  "
echo "========================================="

if [ "$DRY_RUN" == "true" ]; then
    echo "MODE: DRY-RUN (No resources will be deleted)"
    echo "To actually execute deletion, run with: --force"
    echo ""
    echo "The following resources would be deleted:"
    
    echo "1. Helm Releases in aiaad-infra namespace:"
    helm ls -n aiaad-infra 2>/dev/null || echo "None found"
    
    echo "2. PVCs in aiaad-infra namespace:"
    kubectl get pvc -n aiaad-infra 2>/dev/null || echo "None found"
    
    echo "3. Namespaces:"
    echo "- aiaad-platform"
    echo "- aiaad-infra"
    
    echo ""
    echo "External Resources (Neo4j, Foundry, ADO, SharePoint) are intrinsically PROTECTED."
    echo "No external APIs are called by this script."
    exit 0
fi

echo "MODE: DESTRUCTIVE (Deleting resources...)"

# Delete helm releases
echo "Uninstalling helm releases..."
helm uninstall aiaad-temporal -n aiaad-infra --ignore-not-found || true
helm uninstall aiaad-kafka -n aiaad-infra --ignore-not-found || true
helm uninstall aiaad-postgres -n aiaad-infra --ignore-not-found || true

# Delete Namespaces
echo "Deleting namespaces..."
kubectl delete namespace aiaad-platform --ignore-not-found || true
kubectl delete namespace aiaad-infra --ignore-not-found || true

echo "Teardown complete."
