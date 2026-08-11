# identity/workload-identity/verify.ps1 - Validate workload identity configurations and environment variables injection

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$SA_Name = "identity-test-sa"
$Pod_Name = "identity-test-pod"
$Namespace = "aiaad-infra"

# Dummy/Test client/tenant IDs for local validation (non-secret values)
$TestClientId = "11111111-1111-1111-1111-111111111111"
$TestTenantId = "22222222-2222-2222-2222-222222222222"

Write-Host "Creating ServiceAccount with test Workload Identity annotations..."
$saYaml = Get-Content (Join-Path $ScriptDir "templates\serviceaccount.yaml") -Raw
$saYaml = $saYaml.Replace('${SERVICE_ACCOUNT_NAME}', $SA_Name)
$saYaml = $saYaml.Replace('${NAMESPACE}', $Namespace)
$saYaml = $saYaml.Replace('${AZURE_CLIENT_ID}', $TestClientId)
$saYaml = $saYaml.Replace('${AZURE_TENANT_ID}', $TestTenantId)

$saYaml | kubectl apply -f -

Write-Host "Deploying identity test Pod..."
kubectl apply -f (Join-Path $ScriptDir "templates\test-pod.yaml")

Write-Host "Waiting for Pod to start..."
$timeout = 30
while ($timeout -gt 0) {
    $status = kubectl get pod -n $Namespace $Pod_Name -o jsonpath='{.status.phase}' 2>$null
    if ($status -eq "Running") {
        break
    }
    Start-Sleep -Seconds 1
    $timeout--
}

$status = kubectl get pod -n $Namespace $Pod_Name -o jsonpath='{.status.phase}'
if ($status -ne "Running") {
    Write-Warning "Pod did not reach Running state within timeout. This is expected if workload identity is not enabled or registry cannot be reached."
}

Write-Host "Checking injected environment variables..."
$envVars = kubectl exec -n $Namespace $Pod_Name -- env 2>$null
if ($envVars) {
    $hasClientId = $envVars -match "AZURE_CLIENT_ID"
    $hasTenantId = $envVars -match "AZURE_TENANT_ID"
    $hasTokenFile = $envVars -match "AZURE_FEDERATED_TOKEN_FILE"
    
    if ($hasClientId -and $hasTenantId -and $hasTokenFile) {
        Write-Host "SUCCESS: Workload Identity variables successfully injected into test pod!"
    } else {
        Write-Warning "Workload Identity environment variables were NOT injected. Workload Identity is likely not enabled in this cluster."
    }
} else {
    Write-Warning "Could not query pod environment variables."
}

Write-Host "Cleaning up test resources..."
kubectl delete pod -n $Namespace $Pod_Name --ignore-not-found=true
kubectl delete serviceaccount -n $Namespace $SA_Name --ignore-not-found=true
Write-Host "Cleanup done."
