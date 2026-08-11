$ErrorActionPreference = "Continue"

Write-Host "Running Neo4j Connectivity Smoke Test..."

$EnvFile = Join-Path $PSScriptRoot "..\environments\hackathon\environment.yaml"
if (-not (Test-Path $EnvFile)) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $EnvFile"
    exit 1
}

$EnvContent = Get-Content $EnvFile -Raw
$Neo4jUri = $null
if ($EnvContent -match 'neo4jUri:\s*"([^"]*)"') {
    $Neo4jUri = $Matches[1]
}

if (-not $Neo4jUri -or $Neo4jUri -match "placeholder") {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: NEO4J_URI is set to a placeholder value ('$Neo4jUri'). A real Neo4j Aura instance URI is required."
    exit 1
}

Write-Host "Spinning up Neo4j client pod with Key Vault mount..."
$TestPod = "neo4j-smoke-test-$PID"

$PodYaml = @"
apiVersion: v1
kind: Pod
metadata:
  name: $TestPod
  namespace: aiaad-platform
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: aiaad-platform-sa
  containers:
  - name: neo4j-client
    image: neo4j:5.9.0-community
    command: ["sleep", "120"]
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets"
      readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "aiaad-keyvault-spc"
"@

$PodYaml | kubectl apply -f -
$null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=60s 2>$null

Write-Host "Executing harmless test query (RETURN 1 AS connected)..."
$out = kubectl exec -n aiaad-platform $TestPod -- sh -c "
  NEO4J_PASSWORD=\$(cat /mnt/secrets/aiaad-neo4j-password)
  echo `"RETURN 1 AS connected;`" | cypher-shell -a `"$Neo4jUri`" -u `"neo4j`" -p `"\$NEO4J_PASSWORD`"
" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Neo4j connectivity verified successfully!"
    Write-Host $out
    $status = "READY"
} else {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Connection to Neo4j failed. Verify credentials and network egress."
    $status = "BLOCKED"
}

$null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null
if ($status -eq "READY") {
    exit 0
} else {
    exit 1
}
