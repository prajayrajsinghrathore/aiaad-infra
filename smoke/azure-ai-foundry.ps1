$ErrorActionPreference = "Continue"

Write-Host "Running Azure AI Foundry Connectivity & Auth Smoke Test..."

$EnvFile = Join-Path $PSScriptRoot "..\environments\hackathon\environment.yaml"
if (-not (Test-Path $EnvFile)) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $EnvFile"
    exit 1
}

$EnvContent = Get-Content $EnvFile -Raw
$Endpoint = $null
if ($EnvContent -match 'azureAiFoundryEndpoint:\s*"([^"]*)"') {
    $Endpoint = $Matches[1]
}

if (-not $Endpoint -or $Endpoint -match "placeholder") {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Azure AI Foundry endpoint is set to a placeholder ('$Endpoint'). Update environments/hackathon/environment.yaml with the real endpoint before running this test."
    exit 1
}

Write-Host "Endpoint: $Endpoint"
Write-Host "Testing network connectivity and TLS..."

$TestPod = "foundry-smoke-$PID"
$null = kubectl run $TestPod -n aiaad-platform --image=curlimages/curl --restart=Never -- sleep 60 2>$null
$null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=30s 2>$null

$null = kubectl exec -n aiaad-platform $TestPod -- curl -s --connect-timeout 5 -I "$Endpoint" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[READY] Network reachable."
} else {
    Write-Host "[BLOCKED] Network unreachable or DNS resolution failed for $Endpoint."
    $null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
    exit 1
}

$null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null

Write-Host "`nNote: Full authentication via Workload Identity (federated credentials) must be validated by the application SDK (e.g. DefaultAzureCredential). This script validates the network path is open."
Write-Host "STATUS=READY"
exit 0
