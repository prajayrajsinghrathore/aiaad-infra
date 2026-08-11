# bootstrap/deploy-minio.ps1
param (
    [string]$Environment = "hackathon"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying MinIO for environment: $Environment"

# 1. Parse storage class
$storageYamlPath = "environments\$Environment\storage-values.yaml"
if (-Not (Test-Path $storageYamlPath)) {
    throw "Storage values not found at $storageYamlPath"
}
$storageContent = Get-Content $storageYamlPath -Raw

$storageClass = "standard"
if ($storageContent -match 'storageClass:\s*"([^"]*)"' -or $storageContent -match "storageClass:\s*([^\s#]+)") {
    $storageClass = $Matches[1].Trim()
}

$minioSize = "5Gi"
if ($storageContent -match 'minio:\s*\n\s*storageSize:\s*([^\s#]+)') {
    $minioSize = $Matches[1].Trim()
}

Write-Host "Using StorageClass: $storageClass, Size: $minioSize"

# 2. Add MinIO Helm repo and update
Write-Host "Adding MinIO Helm repo..."
helm repo add minio https://charts.min.io/
helm repo update minio

# 3. Deploy using Helm
# Pinning the chart version as required
$chartVersion = "5.4.0"

Write-Host "Deploying minio/minio chart version $chartVersion..."
helm upgrade --install aiaad-minio minio/minio `
    --version $chartVersion `
    --namespace aiaad-infra `
    -f helm/minio/values.base.yaml `
    -f helm/minio/values.$Environment.yaml `
    --set persistence.storageClass=$storageClass `
    --set persistence.size=$minioSize `
    --wait --timeout 5m

Write-Host "MinIO deployment initiated and wait condition satisfied."

# 4. Verify persistence
Write-Host "Deployment completed. Showing pods..."
kubectl get pods -n aiaad-infra -l app.kubernetes.io/name=minio

Write-Host "INF-10 MinIO deployment script completed successfully."
