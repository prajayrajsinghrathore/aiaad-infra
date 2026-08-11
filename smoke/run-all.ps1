$ErrorActionPreference = "Continue"

Write-Host "Running Infrastructure Smoke Suite..."
$Report = @{}
$FailCount = 0

function Add-Check {
    param($Component, $Status, $Reason)
    if ($Status -eq "FAIL") {
        $script:FailCount += 1
    }
    Write-Host "[$Status] $($Component): $Reason"
    $script:Report[$Component] = @{ status = $Status; reason = $Reason }
}

# 1. Namespaces
$null = kubectl get ns aiaad-infra 2>$null
$infraOk = $LASTEXITCODE -eq 0
$null = kubectl get ns aiaad-platform 2>$null
$platOk = $LASTEXITCODE -eq 0

if ($infraOk -and $platOk) {
    Add-Check "Namespaces" "PASS" "Required namespaces exist."
} else {
    Add-Check "Namespaces" "FAIL" "Missing aiaad-infra or aiaad-platform."
}

# 2. Postgres
$null = kubectl get statefulset aiaad-postgres-postgresql -n aiaad-infra 2>$null
if ($LASTEXITCODE -eq 0) {
    $ready = kubectl get statefulset aiaad-postgres-postgresql -n aiaad-infra -o jsonpath='{.status.readyReplicas}'
    if ($ready -eq "1") {
        Add-Check "Postgres" "PASS" "Postgres is ready."
    } else {
        Add-Check "Postgres" "FAIL" "Postgres pod not ready."
    }
} else {
    Add-Check "Postgres" "FAIL" "Postgres StatefulSet not found."
}

# 3. Temporal
$null = kubectl get deploy aiaad-temporal-frontend -n aiaad-infra 2>$null
if ($LASTEXITCODE -eq 0) {
    $ready = kubectl get deploy aiaad-temporal-frontend -n aiaad-infra -o jsonpath='{.status.readyReplicas}'
    if ([int]$ready -gt 0) {
        Add-Check "Temporal" "PASS" "Temporal frontend is ready."
    } else {
        Add-Check "Temporal" "FAIL" "Temporal frontend pod not ready."
    }
} else {
    Add-Check "Temporal" "FAIL" "Temporal deployment not found."
}

# 4. Kafka
$null = kubectl get statefulset aiaad-kafka-controller -n aiaad-infra 2>$null
if ($LASTEXITCODE -eq 0) {
    $ready = kubectl get statefulset aiaad-kafka-controller -n aiaad-infra -o jsonpath='{.status.readyReplicas}'
    if ($ready -eq "1") {
        Add-Check "Kafka" "PASS" "Kafka controller is ready."
    } else {
        Add-Check "Kafka" "FAIL" "Kafka controller not ready."
    }
} else {
    Add-Check "Kafka" "FAIL" "Kafka StatefulSet not found."
}

# 5. Object Storage
$null = kubectl get statefulset aiaad-minio -n aiaad-infra 2>$null
$minioSsOk = $LASTEXITCODE -eq 0
$null = kubectl get deploy aiaad-minio -n aiaad-infra 2>$null
$minioDepOk = $LASTEXITCODE -eq 0

if ($minioSsOk -or $minioDepOk) {
    Add-Check "ObjectStorage" "PASS" "Minio deployed."
} else {
    Add-Check "ObjectStorage" "SKIPPED" "Minio optional component not installed."
}

# 6. Istio Routing
$null = kubectl get virtualservice aiaad-platform-routing -n aiaad-platform 2>$null
if ($LASTEXITCODE -eq 0) {
    Add-Check "IstioRouting" "PASS" "Platform routing virtualservice exists."
} else {
    Add-Check "IstioRouting" "FAIL" "Platform routing virtualservice missing."
}

# 7. External Connectivity
$TestPod = "smoke-curl-$PID"
$null = kubectl run $TestPod -n aiaad-platform --image=curlimages/curl --restart=Never -- sleep 60 2>$null
if ($LASTEXITCODE -eq 0) {
    $null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=30s 2>$null
    
    $null = kubectl exec -n aiaad-platform $TestPod -- curl -s --connect-timeout 5 -I https://neo4j.com 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-Check "Neo4jConnectivity" "PASS" "Reachable."
    } else {
        Add-Check "Neo4jConnectivity" "FAIL" "Unreachable."
    }

    $null = kubectl exec -n aiaad-platform $TestPod -- curl -s --connect-timeout 5 -I https://dev.azure.com 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-Check "FoundryConnectivity" "PASS" "Reachable."
    } else {
        Add-Check "FoundryConnectivity" "FAIL" "Unreachable."
    }
    
    $null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
} else {
    Add-Check "Connectivity" "FAIL" "Failed to launch curl test pod."
}

Write-Host "`n--- Machine Readable Report (JSON) ---"
$JsonReport = $Report | ConvertTo-Json -Depth 3
$JsonReport | Set-Content "smoke-report.json"
Write-Host $JsonReport
Write-Host "`n"

if ($FailCount -eq 0) {
    Write-Host "OVERALL STATUS: READY"
    exit 0
} else {
    Write-Host "OVERALL STATUS: BLOCKED ($FailCount failures)"
    exit 1
}
