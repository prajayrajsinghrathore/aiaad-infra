#!/usr/bin/env bash
set -eo pipefail

echo "=== Temporal E2E Smoke Test ==="

# Create configmap with python scripts
kubectl create configmap temporal-smoke-fixture --from-file=smoke/temporal-fixture -n aiaad-infra --dry-run=client -o yaml | kubectl apply -f -

WF_ID="smoke-wf-$(date +%s)"

echo "1. Starting the Temporal worker pod..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: temporal-smoke-worker
  namespace: aiaad-infra
  labels:
    app: temporal-smoke-worker
spec:
  containers:
  - name: worker
    image: python:3.12.10
    command: ["/bin/sh", "-c"]
    args:
    - pip install temporalio && python /fixture/worker.py
    volumeMounts:
    - name: fixture
      mountPath: /fixture
  volumes:
  - name: fixture
    configMap:
      name: temporal-smoke-fixture
  restartPolicy: Never
EOF

echo "Waiting for worker to start..."
kubectl wait --for=condition=Ready pod/temporal-smoke-worker -n aiaad-infra --timeout=60s || { echo "Worker failed to start"; kubectl logs temporal-smoke-worker -n aiaad-infra; exit 1; }

echo "2. Starting the workflow from client..."
kubectl run temporal-smoke-client-start --rm -i --tty=false --image=python:3.12.10 -n aiaad-infra --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "client",
      "image": "python:3.12.10",
      "command": ["/bin/sh", "-c"],
      "args": ["pip install temporalio -q && python /fixture/client.py start --id '$WF_ID'"],
      "volumeMounts": [{"name": "fixture", "mountPath": "/fixture"}]
    }],
    "volumes": [{"name": "fixture", "configMap": {"name": "temporal-smoke-fixture"}}]
  }
}'

echo "3. Restarting the worker pod to verify durability..."
kubectl delete pod temporal-smoke-worker -n aiaad-infra
# Apply it again
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: temporal-smoke-worker
  namespace: aiaad-infra
  labels:
    app: temporal-smoke-worker
spec:
  containers:
  - name: worker
    image: python:3.12.10
    command: ["/bin/sh", "-c"]
    args:
    - pip install temporalio && python /fixture/worker.py
    volumeMounts:
    - name: fixture
      mountPath: /fixture
  volumes:
  - name: fixture
    configMap:
      name: temporal-smoke-fixture
  restartPolicy: Never
EOF

kubectl wait --for=condition=Ready pod/temporal-smoke-worker -n aiaad-infra --timeout=60s

echo "4. Signaling the workflow to complete..."
kubectl run temporal-smoke-client-signal --rm -i --tty=false --image=python:3.12.10 -n aiaad-infra --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "client",
      "image": "python:3.12.10",
      "command": ["/bin/sh", "-c"],
      "args": ["pip install temporalio -q && python /fixture/client.py signal --id '$WF_ID'"],
      "volumeMounts": [{"name": "fixture", "mountPath": "/fixture"}]
    }],
    "volumes": [{"name": "fixture", "configMap": {"name": "temporal-smoke-fixture"}}]
  }
}'

echo "Cleaning up..."
kubectl delete pod temporal-smoke-worker -n aiaad-infra
kubectl delete configmap temporal-smoke-fixture -n aiaad-infra

echo "=== Smoke Test Complete ==="
