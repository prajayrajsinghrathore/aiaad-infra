param (
    [switch]$Force = $false
)
$ErrorActionPreference = "Continue"

Write-Host "========================================="
Write-Host "  aiaad-infra Hackathon Teardown Script  "
Write-Host "========================================="

if (-not $Force) {
    Write-Host "MODE: DRY-RUN (No resources will be deleted)"
    Write-Host "To actually execute deletion, run with: -Force"
    Write-Host "`nThe following resources would be deleted:"
    
    Write-Host "`n1. Helm Releases in aiaad-infra namespace:"
    helm ls -n aiaad-infra
    
    Write-Host "`n2. PVCs in aiaad-infra namespace:"
    kubectl get pvc -n aiaad-infra
    
    Write-Host "`n3. Namespaces:"
    Write-Host "- aiaad-platform"
    Write-Host "- aiaad-infra"
    
    Write-Host "`nExternal Resources (Neo4j, Foundry, ADO, SharePoint) are intrinsically PROTECTED."
    Write-Host "No external APIs are called by this script."
    exit 0
}

Write-Host "MODE: DESTRUCTIVE (Deleting resources...)"

Write-Host "Uninstalling helm releases..."
$null = helm uninstall aiaad-temporal -n aiaad-infra --ignore-not-found 2>$null
$null = helm uninstall aiaad-kafka -n aiaad-infra --ignore-not-found 2>$null
$null = helm uninstall aiaad-postgres -n aiaad-infra --ignore-not-found 2>$null

Write-Host "Deleting namespaces (this cleans up PVCs)..."
$null = kubectl delete namespace aiaad-platform --ignore-not-found 2>$null
$null = kubectl delete namespace aiaad-infra --ignore-not-found 2>$null

Write-Host "Teardown complete."
