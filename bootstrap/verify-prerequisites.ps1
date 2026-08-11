# verify-prerequisites.ps1 - check tool availability, configurations, and cluster connectivity

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path "$ScriptDir\.."

Write-Host "Checking required CLI tools..."
$tools = @("kubectl", "helm", "git")
foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "Required tool '$tool' is not installed."
        exit 1
    }
    Write-Host "  - ${tool}: found"
}

# 1. Parse configuration files (using simple string extraction to avoid external dependencies)
$envFile = Join-Path $RepoRoot "environments\hackathon\environment.yaml"
$storageFile = Join-Path $RepoRoot "environments\hackathon\storage-values.yaml"

if (-not (Test-Path $envFile)) {
    Write-Error "Missing environment.yaml at $envFile"
    exit 1
}

$envContent = Get-Content $envFile -Raw
$targetContext = ""
if ($envContent -match 'targetContext:\s*"([^"]*)"' -or $envContent -match "targetContext:\s*'([^']*)'" -or $envContent -match 'targetContext:\s*([^\s#]+)') {
    $targetContext = $Matches[1].Trim()
}

if ([string]::IsNullOrWhiteSpace($targetContext)) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: kubernetes.targetContext is not set in environments/hackathon/environment.yaml"
    exit 1
}

# 2. Verify current kubectl context matches targetContext
Write-Host "Verifying target context..."
$currentContext = (kubectl config current-context).Trim()
if ($currentContext -ne $targetContext) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Current context '$currentContext' does not match targetContext '$targetContext' defined in environment.yaml"
    exit 1
}

# 3. Verify cluster connectivity
Write-Host "Checking cluster connectivity..."
$null = kubectl cluster-info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "STATUS=BLOCKED"
    Write-Host "BLOCKERS/DEVIATIONS: Cannot connect to Kubernetes cluster using context '$targetContext'."
    exit 1
}

# 4. Check for existing Gateway/Istio installation
Write-Host "Checking for existing Istio installation..."
$gatewayValuesFile = Join-Path $RepoRoot "environments\hackathon\gateway-values.yaml"
$gwContent = Get-Content $gatewayValuesFile -Raw
$gwName = "aiaad-gateway"
$gwNamespace = "istio-system"
if ($gwContent -match 'name:\s*"([^"]*)"' -or $gwContent -match "name:\s*([^\s#]+)") { $gwName = $Matches[1].Trim() }
if ($gwContent -match 'namespace:\s*"([^"]*)"' -or $gwContent -match "namespace:\s*([^\s#]+)") { $gwNamespace = $Matches[1].Trim() }

try {
    $null = kubectl get gateway -n $gwNamespace $gwName -o name 2>$null
    Write-Host "  - Existing Gateway $gwNamespace/$gwName found."
} catch {
    Write-Warning "Could not find Gateway $gwNamespace/$gwName in the cluster. It must be pre-provisioned."
}

# 5. Check storage class configuration
Write-Host "Checking storage class availability..."
$storageContent = Get-Content $storageFile -Raw
$storageClass = "managed-csi"
if ($storageContent -match 'storageClass:\s*"([^"]*)"' -or $storageContent -match "storageClass:\s*([^\s#]+)") {
    $storageClass = $Matches[1].Trim()
}

$scExists = $false
try {
    $scs = kubectl get storageclass -o jsonpath='{.items[*].metadata.name}'
    if ($scs -match $storageClass) {
        $scExists = $true
        Write-Host "  - StorageClass '${storageClass}' verified in cluster."
    }
} catch {
    Write-Warning "Failed to query storage classes from cluster."
}

if (-not $scExists) {
    Write-Warning "StorageClass '${storageClass}' is not found or not queryable in the active cluster context."
}

Write-Host "All prerequisites checks completed."
