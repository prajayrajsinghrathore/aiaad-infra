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

# 7. External Connectivity (Neo4j, OpenAI, ADO/Graph)
Write-Host "`nExecuting specialized diagnostic scripts..."

# Neo4j
& "$PSScriptRoot\neo4j-connectivity.ps1" >$null 2>&1
if ($LASTEXITCODE -eq 0) {
    Add-Check "Neo4jConnectivity" "PASS" "Reachable and queried successfully."
} else {
    Add-Check "Neo4jConnectivity" "FAIL" "Failed to connect or query."
}

# OpenAI
& "$PSScriptRoot\openai.ps1" >$null 2>&1
if ($LASTEXITCODE -eq 0) {
    Add-Check "OpenAiConnectivity" "PASS" "Reachable."
} else {
    Add-Check "OpenAiConnectivity" "FAIL" "Unreachable."
}

# ADO & Graph/SharePoint
& "$PSScriptRoot\ado-graph-connectivity.ps1" >$null 2>&1
if ($LASTEXITCODE -eq 0) {
    Add-Check "AdoGraphConnectivity" "PASS" "Reachable."
} else {
    Add-Check "AdoGraphConnectivity" "FAIL" "Unreachable."
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
