#!/usr/bin/env bash
set -e

echo "Running Neo4j Connectivity Smoke Test..."

ENV_FILE="$(dirname "$0")/../environments/hackathon/environment.yaml"
if [ ! -f "$ENV_FILE" ]; then
    echo "STATUS=BLOCKED"
    echo "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $ENV_FILE"
    exit 1
fi

NEO4J_URI=$(grep "neo4jUri:" "$ENV_FILE" | awk -F'"' '{print $2}')

if [[ -z "$NEO4J_URI" || "$NEO4J_URI" == *"placeholder"* ]]; then
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: NEO4J_URI is set to a placeholder value ('$NEO4J_URI'). A real Neo4j Aura instance URI is required."
  exit 1
fi

echo "Spinning up Neo4j client pod with Key Vault mount..."
TEST_POD="neo4j-smoke-test-$$"

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
  - name: neo4j-client
    image: neo4j:5.9.0-community
    command: ["sleep", "120"]
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

kubectl wait --for=condition=Ready pod/$TEST_POD -n aiaad-platform --timeout=60s >/dev/null 2>&1 || true

echo "Executing harmless test query (RETURN 1 AS connected)..."
if kubectl exec -n aiaad-platform $TEST_POD -- sh -c "
  NEO4J_PASSWORD=\$(cat /mnt/secrets/aiaad-neo4j-password)
  echo \"RETURN 1 AS connected;\" | cypher-shell -a \"$NEO4J_URI\" -u \"neo4j\" -p \"\$NEO4J_PASSWORD\"
"; then
  echo "Neo4j connectivity verified successfully!"
  kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1
  exit 0
else
  echo "STATUS=BLOCKED"
  echo "BLOCKERS/DEVIATIONS: Connection to Neo4j failed. Verify credentials and network egress."
  kubectl delete pod $TEST_POD -n aiaad-platform --ignore-not-found >/dev/null 2>&1
  exit 1
fi
