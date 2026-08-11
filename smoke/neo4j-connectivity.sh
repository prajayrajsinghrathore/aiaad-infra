#!/usr/bin/env bash
set -e

echo "Running Neo4j Connectivity Smoke Test..."

# Verify the secret exists in the cluster
if ! kubectl get secret aiaad-neo4j-credentials -n aiaad-platform >/dev/null 2>&1; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: Required secret 'aiaad-neo4j-credentials' not found in aiaad-platform namespace."
  exit 1
fi

NEO4J_URI=$(kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_URI}' | base64 --decode)

if [[ "$NEO4J_URI" == *"placeholder"* ]]; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: NEO4J_URI is set to a placeholder value ('$NEO4J_URI'). A real Neo4j Aura instance URI is required."
  exit 1
fi

echo "Spinning up cypher-shell client pod to test connectivity..."
TEST_POD="neo4j-smoke-test-$$"

# Create a pod that runs cypher-shell with the credentials from the secret
kubectl run $TEST_POD -n aiaad-platform --image=neo4j:5.9.0-community --restart=Never \
  --env="NEO4J_URI=$(kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_URI}' | base64 --decode)" \
  --env="NEO4J_USERNAME=$(kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_USERNAME}' | base64 --decode)" \
  --env="NEO4J_PASSWORD=$(kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_PASSWORD}' | base64 --decode)" \
  --command -- sleep 60

kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=30s

echo "Executing harmless test query (RETURN 1 AS connected)..."
if kubectl exec -n aiaad-platform $TEST_POD -- sh -c 'echo "RETURN 1 AS connected;" | cypher-shell -a "$NEO4J_URI" -u "$NEO4J_USERNAME" -p "$NEO4J_PASSWORD"'; then
  echo "Neo4j connectivity verified successfully!"
  kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found
  exit 0
else
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: Connection to Neo4j failed. Verify credentials and network egress."
  kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found
  exit 1
fi
