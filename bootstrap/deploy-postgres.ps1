# bootstrap/deploy-postgres.ps1
param (
    [string]$Environment = "hackathon"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying PostgreSQL for environment: $Environment"

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

$postgresSize = "10Gi"
if ($storageContent -match 'storageSize:\s*([^\s#]+)' ) {
    # It might match postgres first, which is what we want
    $postgresSize = $Matches[1].Trim()
}

Write-Host "Using StorageClass: $storageClass, Size: $postgresSize"

# 2. Create ConfigMap for init scripts in aiaad-infra namespace
Write-Host "Creating ConfigMap for init scripts..."
kubectl create configmap aiaad-postgres-init-scripts `
    --from-file=postgres/init/ `
    --namespace aiaad-infra `
    --dry-run=client -o yaml | kubectl apply -f -

# 3. Add Bitnami Helm repo and update
Write-Host "Adding Bitnami Helm repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami

# 4. Deploy using Helm
# Pinning the chart version as required
$chartVersion = "18.8.7"

Write-Host "Deploying bitnami/postgresql chart version $chartVersion..."
helm upgrade --install aiaad-postgres bitnami/postgresql `
    --version $chartVersion `
    --namespace aiaad-infra `
    -f helm/postgres/values.base.yaml `
    -f helm/postgres/values.$Environment.yaml `
    --set primary.persistence.storageClass=$storageClass `
    --set primary.persistence.size=$postgresSize `
    --wait --timeout 5m

Write-Host "PostgreSQL deployment initiated and wait condition satisfied."

# 5. Verify persistence
Write-Host "Deployment completed. Showing pods..."
kubectl get pods -n aiaad-infra -l app.kubernetes.io/name=postgresql

Write-Host "INF-04 PostgreSQL deployment script completed successfully."
