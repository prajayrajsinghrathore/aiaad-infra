$ErrorActionPreference = "Continue"

Write-Host "Running Neo4j Connectivity Smoke Test..."

$null = kubectl get secret aiaad-neo4j-credentials -n aiaad-platform 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Required secret 'aiaad-neo4j-credentials' not found in aiaad-platform namespace."
    exit 1
}

$Neo4jUriB64 = kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_URI}'
$Neo4jUri = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Neo4jUriB64))

if ($Neo4jUri -match "placeholder") {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: NEO4J_URI is set to a placeholder value ('$Neo4jUri'). A real Neo4j Aura instance URI is required."
    exit 1
}

$Neo4jUserB64 = kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_USERNAME}'
$Neo4jUser = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Neo4jUserB64))

$Neo4jPassB64 = kubectl get secret aiaad-neo4j-credentials -n aiaad-platform -o jsonpath='{.data.NEO4J_PASSWORD}'
$Neo4jPass = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Neo4jPassB64))

Write-Host "Spinning up cypher-shell client pod to test connectivity..."
$TestPod = "neo4j-smoke-test-$PID"

$null = kubectl run $TestPod -n aiaad-platform --image=neo4j:5.9.0-community --restart=Never `
  --env="NEO4J_URI=$Neo4jUri" `
  --env="NEO4J_USERNAME=$Neo4jUser" `
  --env="NEO4J_PASSWORD=$Neo4jPass" `
  --command -- sleep 60

$null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=30s

Write-Host "Executing harmless test query (RETURN 1 AS connected)..."
$queryCmd = "echo `"RETURN 1 AS connected;`" | cypher-shell -a `"$Neo4jUri`" -u `"$Neo4jUser`" -p `"$Neo4jPass`""
$null = kubectl exec -n aiaad-platform $TestPod -- sh -c $queryCmd 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Neo4j connectivity verified successfully!"
    $null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
    exit 0
} else {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Connection to Neo4j failed. Verify credentials and network egress."
    $null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
    exit 1
}
