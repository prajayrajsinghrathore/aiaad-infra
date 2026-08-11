$ErrorActionPreference = "Continue"

Write-Host "Running OpenAI Key Vault Secret Sync Smoke Test..."

$TestPod = "keyvault-smoke-$PID"
Write-Host "Launching test pod to mount SecretProviderClass..."

$PodYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: $TestPod
  namespace: aiaad-platform
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: aiaad-platform-sa
  containers:
  - name: test-container
    image: mcr.microsoft.com/azure-cli:latest
    command: ["sleep", "60"]
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
"@

$PodYaml | kubectl apply -f -
Write-Host "Waiting for pod to start..."
$null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=60s 2>$null

Write-Host "Checking if Kubernetes secret openai-service-account was created..."
$null = kubectl get secret openai-service-account -n aiaad-platform 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[READY] Kubernetes secret 'openai-service-account' successfully synced from Key Vault!"
    $status = "READY"
} else {
    Write-Host "[BLOCKED] Kubernetes secret 'openai-service-account' was not created. Check CSI driver pod logs."
    $status = "BLOCKED"
}

$null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
if ($status -eq "READY") {
    exit 0
} else {
    exit 1
}
