$ErrorActionPreference = "Stop"

Write-Host "=== Temporal E2E Smoke Test ==="

# Create configmap with python scripts
kubectl create configmap temporal-smoke-fixture --from-file=smoke/temporal-fixture -n aiaad-infra --dry-run=client -o yaml | kubectl apply -f -

$WF_ID = "smoke-wf-$(Get-Date -UFormat %s)"
$WF_ID = $WF_ID.Trim()

Write-Host "1. Starting the Temporal worker pod..."
$workerYaml = @"
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
"@

$workerYaml | kubectl apply -f -

Write-Host "Waiting for worker to start..."
kubectl wait --for=condition=Ready pod/temporal-smoke-worker -n aiaad-infra --timeout=120s

Write-Host "2. Starting the workflow from client..."
$clientStartYaml = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: temporal-smoke-client-start
  namespace: aiaad-infra
spec:
  template:
    spec:
      containers:
      - name: client
        image: python:3.12.10
        command: ["/bin/sh", "-c"]
        args:
        - pip install temporalio -q && python /fixture/client.py start --id $WF_ID
        volumeMounts:
        - name: fixture
          mountPath: /fixture
      volumes:
      - name: fixture
        configMap:
          name: temporal-smoke-fixture
      restartPolicy: Never
  backoffLimit: 0
"@

kubectl delete job temporal-smoke-client-start -n aiaad-infra --ignore-not-found=true
$clientStartYaml | kubectl apply -f -
kubectl wait --for=condition=complete job/temporal-smoke-client-start -n aiaad-infra --timeout=120s
kubectl logs job/temporal-smoke-client-start -n aiaad-infra

Write-Host "3. Restarting the worker pod to verify durability..."
kubectl delete pod temporal-smoke-worker -n aiaad-infra --wait=true
$workerYaml | kubectl apply -f -
kubectl wait --for=condition=Ready pod/temporal-smoke-worker -n aiaad-infra --timeout=120s

Write-Host "4. Signaling the workflow to complete..."
$clientSignalYaml = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: temporal-smoke-client-signal
  namespace: aiaad-infra
spec:
  template:
    spec:
      containers:
      - name: client
        image: python:3.12.10
        command: ["/bin/sh", "-c"]
        args:
        - pip install temporalio -q && python /fixture/client.py signal --id $WF_ID
        volumeMounts:
        - name: fixture
          mountPath: /fixture
      volumes:
      - name: fixture
        configMap:
          name: temporal-smoke-fixture
      restartPolicy: Never
  backoffLimit: 0
"@

kubectl delete job temporal-smoke-client-signal -n aiaad-infra --ignore-not-found=true
$clientSignalYaml | kubectl apply -f -
kubectl wait --for=condition=complete job/temporal-smoke-client-signal -n aiaad-infra --timeout=120s
kubectl logs job/temporal-smoke-client-signal -n aiaad-infra

Write-Host "Cleaning up..."
kubectl delete pod temporal-smoke-worker -n aiaad-infra
kubectl delete job temporal-smoke-client-start -n aiaad-infra
kubectl delete job temporal-smoke-client-signal -n aiaad-infra
kubectl delete configmap temporal-smoke-fixture -n aiaad-infra

Write-Host "=== Smoke Test Complete ==="
