$ErrorActionPreference = "Continue"

Write-Host "=========================================="
Write-Host "    INFRASTRUCTURE HEALTH DIAGNOSTIC"
Write-Host "=========================================="
Write-Host ""

$Namespace = "aiaad-infra"
$PlatformNamespace = "aiaad-platform"

Write-Host "1. Namespaces Check"
foreach ($ns in @($Namespace, $PlatformNamespace)) {
    $out = kubectl get ns $ns 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Namespace $ns exists"
    } else {
        Write-Host "[ERROR] Namespace $ns missing"
    }
}
Write-Host ""

Write-Host "2. Internal Services Readiness & Restarts (Postgres, Temporal, Kafka)"
kubectl get pods -n $Namespace -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,STATUS:.status.phase"
Write-Host ""

Write-Host "3. Persistence (PVCs)"
$pvcOut = kubectl get pvc -n $Namespace -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage" 2>$null
if ($LASTEXITCODE -eq 0) {
    $pvcOut
} else {
    Write-Host "No PVCs found."
}
Write-Host ""

Write-Host "4. External Dependency Reachability"
$TestPod = "infra-health-curl"
$null = kubectl run $TestPod -n $PlatformNamespace --image=curlimages/curl --restart=Never -- sleep 60 2>$null
$null = kubectl wait --for=condition=Ready pod/$TestPod -n $PlatformNamespace --timeout=30s 2>$null

$endpoints = @(
    "https://dev.azure.com",
    "https://graph.microsoft.com",
    "https://neo4j.com",
    "https://google.com"
)

foreach ($ep in $endpoints) {
    $null = kubectl exec -n $PlatformNamespace $TestPod -- curl -s --connect-timeout 5 -I $ep 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Reachable: $ep"
    } else {
        Write-Host "[FAIL] Unreachable: $ep"
    }
}

$null = kubectl delete pod $TestPod -n $PlatformNamespace --ignore-not-found 2>$null
Write-Host ""
Write-Host "Diagnostic complete."
