# bootstrap/verify-databases.ps1
$ErrorActionPreference = "Stop"
Write-Host "Starting database verification..."

# Function to run query via kubectl exec
function Invoke-Psql {
    param([string]$Database, [string]$User, [string]$Password, [string]$Query)
    $podName = "aiaad-postgres-postgresql-0"
    $namespace = "aiaad-infra"
    
    # We use base64 to safely pass the query through bash
    $queryBytes = [System.Text.Encoding]::UTF8.GetBytes($Query)
    $queryB64 = [System.Convert]::ToBase64String($queryBytes)
    $cmd = "echo $queryB64 | base64 -d | PGPASSWORD=$Password psql -U $User -d $Database -t"
    
    $result = kubectl exec -n $namespace $podName -c postgresql -- bash -c $cmd 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "psql failed: $($result -join ' ')"
    }
    return ($result -join "`n").Trim()
}

Write-Host "`n1. Verifying temporal databases exist and are reachable by Temporal credentials..."
$temporalResult = Invoke-Psql -Database "temporal" -User "temporal_app" -Password "temporal_app_password" -Query "SELECT current_database();"
Write-Host "Temporal connection: $temporalResult"

$temporalVisResult = Invoke-Psql -Database "temporal_visibility" -User "temporal_app" -Password "temporal_app_password" -Query "SELECT current_database();"
Write-Host "Temporal Visibility connection: $temporalVisResult"

Write-Host "`n2. Verifying vector extension works in aiaad database..."
$vectorResult = Invoke-Psql -Database "aiaad" -User "aiaad_app" -Password "aiaad_app_password" -Query "SELECT extname FROM pg_extension WHERE extname = 'vector';"
if ($vectorResult -match "vector") {
    Write-Host "Vector extension is active."
} else {
    throw "Vector extension not found in aiaad database: $vectorResult"
}

Write-Host "`n3. Verifying cross-service SQL access is forbidden..."
# aiaad_app trying to connect to temporal
try {
    $null = Invoke-Psql -Database "temporal" -User "aiaad_app" -Password "aiaad_app_password" -Query "SELECT 1;"
    Write-Warning "aiaad_app was able to connect to temporal database! This should be forbidden."
    exit 1
} catch {
    Write-Host "Successfully prevented aiaad_app from accessing temporal database."
}

# temporal_app trying to connect to aiaad
try {
    $null = Invoke-Psql -Database "aiaad" -User "temporal_app" -Password "temporal_app_password" -Query "SELECT 1;"
    Write-Warning "temporal_app was able to connect to aiaad database! This should be forbidden."
    exit 1
} catch {
    Write-Host "Successfully prevented temporal_app from accessing aiaad database."
}

Write-Host "`nAll verifications passed successfully!"
