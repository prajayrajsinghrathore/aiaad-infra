# minio/smoke/smoke-test.ps1
$ErrorActionPreference = "Stop"
$namespace = "aiaad-infra"

Write-Host "Running MinIO smoke test..."

# 1. Create a test pod with MinIO Client (mc)
Write-Host "Creating ephemeral MinIO client pod..."
kubectl run minio-client-test -n $namespace --image=minio/mc --restart=Never --command -- sleep 3600 | Out-Null
kubectl wait --for=condition=ready pod/minio-client-test -n $namespace --timeout=60s | Out-Null

# 2. Configure mc alias
Write-Host "Configuring MinIO client alias..."
# Using the default credentials from values.base.yaml (minioadmin:minioadmin)
kubectl exec -n $namespace minio-client-test -- mc alias set myminio http://aiaad-minio:9000 minioadmin minioadmin | Out-Null

# 3. Create a test file
Write-Host "Creating test file..."
kubectl exec -n $namespace minio-client-test -- sh -c "echo 'smoke test content' > /tmp/test-file.txt" | Out-Null

# 4. Upload to MinIO hackathon bucket
Write-Host "Uploading to MinIO..."
kubectl exec -n $namespace minio-client-test -- mc mb myminio/hackathon --ignore-existing | Out-Null
kubectl exec -n $namespace minio-client-test -- mc cp /tmp/test-file.txt myminio/hackathon/test-file.txt | Out-Null

# 5. Read back from MinIO
Write-Host "Reading back from MinIO..."
$content = kubectl exec -n $namespace minio-client-test -- mc cat myminio/hackathon/test-file.txt 2>&1

if ($content -match "smoke test content") {
    Write-Host "Upload and Read PASSED!"
} else {
    throw "Read verification FAILED! Got: $content"
}

# 6. Delete the file
Write-Host "Deleting test file from MinIO..."
kubectl exec -n $namespace minio-client-test -- mc rm myminio/hackathon/test-file.txt | Out-Null

# 7. Cleanup
Write-Host "Cleaning up ephemeral client..."
kubectl delete pod minio-client-test -n $namespace --force --grace-period=0 | Out-Null

Write-Host "MinIO smoke test PASSED successfully!"
