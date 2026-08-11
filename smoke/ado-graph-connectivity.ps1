$ErrorActionPreference = "Continue"

Write-Host "Running ADO & Graph/SharePoint Network Connectivity Diagnostic..."

$EnvFile = Join-Path $PSScriptRoot "..\environments\hackathon\environment.yaml"
if (-not (Test-Path $EnvFile)) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Cannot find environment.yaml at $EnvFile"
    exit 1
}

$EnvContent = Get-Content $EnvFile -Raw
$SpEndpoint = $null
if ($EnvContent -match 'sharePointTenantUrl:\s*"([^"]*)"') {
    $SpEndpoint = $Matches[1]
}

if (-not $SpEndpoint -or $SpEndpoint -match "placeholder") {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: SharePoint endpoint is set to a placeholder ('$SpEndpoint'). Update environments/hackathon/environment.yaml with the real tenant URL before running this test."
    exit 1
}

$TestPod = "ado-graph-smoke-$PID"
$null = kubectl run $TestPod -n aiaad-platform --image=curlimages/curl --restart=Never -- sleep 60 2>$null
$null = kubectl wait --for=condition=Ready pod/$TestPod -n aiaad-platform --timeout=30s 2>$null

$Failures = 0

function Verify-Endpoint {
    param($Name, $Url)
    Write-Host -NoNewline "Testing $Name ($Url)... "
    
    $null = kubectl exec -n aiaad-platform $TestPod -- curl -s --connect-timeout 5 -I "$Url" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[READY]"
    } else {
        Write-Host "[BLOCKED] - Network unreachable or DNS resolution failed."
        $script:Failures++
    }
}

Verify-Endpoint "Azure DevOps" "https://dev.azure.com"
Verify-Endpoint "Microsoft Graph" "https://graph.microsoft.com"
Verify-Endpoint "Entra ID (Login)" "https://login.microsoftonline.com"
Verify-Endpoint "SharePoint (Root)" $SpEndpoint

Write-Host -NoNewline "Testing Authenticated ADO access (PAT)... "
$null = kubectl get secret aiaad-ado-credentials -n aiaad-platform 2>$null
if ($LASTEXITCODE -eq 0) {
    $ADO_PAT_B64 = kubectl get secret aiaad-ado-credentials -n aiaad-platform -o jsonpath="{.data.ADO_PAT}" 2>$null
    if ($ADO_PAT_B64) {
        $ADO_PAT = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ADO_PAT_B64))
        $null = kubectl exec -n aiaad-platform $TestPod -- sh -c "curl -s --connect-timeout 5 -u `":$ADO_PAT`" https://dev.azure.com >/dev/null" 2>$null
        Write-Host "[READY] Connectivity established using PAT."
    } else {
        Write-Host "[BLOCKED] ADO_PAT key missing in secret."
    }
} else {
    Write-Host "[SKIPPED] No 'aiaad-ado-credentials' secret provided."
}

$null = kubectl delete pod $TestPod -n aiaad-platform --ignore-not-found 2>$null

if ($Failures -eq 0) {
    Write-Host "`nOVERALL STATUS: READY"
    exit 0
} else {
    Write-Host "`nOVERALL STATUS: BLOCKED ($Failures failures)"
    exit 1
}
