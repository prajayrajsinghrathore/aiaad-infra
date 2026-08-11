# aiaad-infra bootstrap entrypoint for PowerShell
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptDir\.."

Write-Host "========================================="
Write-Host "  aiaad-infra Bootstrap Orchestration    "
Write-Host "========================================="

Write-Host "`n[STEP 1/7] Running prerequisite validation..."
& "$ScriptDir\verify-prerequisites.ps1"

Write-Host "`n[STEP 2/7] Applying Kubernetes Namespaces..."
kubectl apply -f "$RepoRoot\namespaces\aiaad-infra.yaml"
kubectl apply -f "$RepoRoot\namespaces\aiaad-platform.yaml"
kubectl apply -f "$RepoRoot\namespaces\aiaad-platform-sa.yaml"

Write-Host "`n[STEP 3/7] Deploying Required Component: PostgreSQL..."
& "$ScriptDir\deploy-postgres.ps1"

Write-Host "`n[STEP 4/7] Deploying Required Component: Kafka..."
& "$ScriptDir\deploy-kafka.ps1"

Write-Host "`n[STEP 5/7] Deploying Required Component: Temporal..."
& "$ScriptDir\deploy-temporal.ps1"

Write-Host "`n[STEP 6/7] Deploying Optional Component: Minio..."
Write-Host "Skipping optional Minio deployment by default. Run deploy-minio.ps1 manually if required."

Write-Host "`n[STEP 7/7] Verifying Infrastructure Health..."
if (Test-Path "$RepoRoot\admin\diagnostics\infra-health.ps1") {
    & "$RepoRoot\admin\diagnostics\infra-health.ps1"
}

Write-Host "`n=== Bootstrap sequence completed successfully ==="
