$ErrorActionPreference = "Continue"

Write-Host "Running Azure Storage Account & Workload Identity connectivity test..."

$EnvFile = Join-Path $PSScriptRoot "..\environments\hackathon\environment.yaml"
if (-not (Test-Path $EnvFile)) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Cannot find environment.yaml"
    exit 1
}

$EnvContent = Get-Content $EnvFile -Raw
$StorageAccount = $null
$ClientId = $null
$TenantId = $null

if ($EnvContent -match 'storageAccountName:\s*"([^"]*)"') { $StorageAccount = $Matches[1] }
if ($EnvContent -match 'workloadIdentityClientId:\s*"([^"]*)"') { $ClientId = $Matches[1] }
if ($EnvContent -match 'tenantId:\s*"([^"]*)"') { $TenantId = $Matches[1] }

if (-not $StorageAccount -or -not $ClientId -or -not $TenantId) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Missing storage account name, Client ID, or Tenant ID in environment.yaml"
    exit 1
}

$TestPod = "storage-smoke-$PID"
Write-Host "Launching test pod in aiaad-platform namespace..."

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
  - name: azure-cli
    image: mcr.microsoft.com/azure-cli:latest
    command: ["sleep", "120"]
"@

$PodYaml | kubectl apply -f -
kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=60s

Write-Host "Authenticating via Workload Identity and listing containers..."
$out = kubectl exec -n aiaad-platform $TestPod -- sh -c "
  az login --federated-token `$(cat `$AZURE_FEDERATED_TOKEN_FILE) --service-principal -u `$AZURE_CLIENT_ID -t `$AZURE_TENANT_ID --allow-no-subscriptions
  az storage container list --account-name $StorageAccount --auth-mode login -o table
"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[READY] Successfully authenticated and retrieved container list!"
    Write-Host $out
    $status = "READY"
} else {
    Write-Host "[BLOCKED] Failed to authenticate or retrieve container list from storage account $StorageAccount."
    $status = "BLOCKED"
}

$null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
if ($status -eq "READY") {
    exit 0
} else {
    exit 1
}
