# bootstrap/deploy-kafka.ps1
param (
    [string]$Environment = "hackathon"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying Kafka for environment: $Environment"

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

$kafkaSize = "2Gi"

Write-Host "Using StorageClass: $storageClass, Size: $kafkaSize"

# 2. Add Bitnami Helm repo and update
Write-Host "Adding Bitnami Helm repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami

# 3. Deploy using Helm
# Pinning the chart version as required
$chartVersion = "31.5.0"

Write-Host "Deploying local aiaad-kafka chart version $chartVersion..."
helm upgrade --install aiaad-kafka ./helm/kafka `
    --namespace aiaad-infra `
    -f helm/kafka/values.base.yaml `
    -f helm/kafka/values.$Environment.yaml `
    --set kafka.persistence.storageClass=$storageClass `
    --set kafka.persistence.size=$kafkaSize `
    --wait --timeout 5m

Write-Host "Kafka deployment initiated and wait condition satisfied."

# 4. Verify deployment
Write-Host "Deployment completed. Showing pods..."
kubectl get pods -n aiaad-infra -l app.kubernetes.io/instance=aiaad-kafka

Write-Host "INF-08 Kafka deployment script completed successfully."
