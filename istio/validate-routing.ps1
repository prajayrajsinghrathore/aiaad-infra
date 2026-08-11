$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = (Get-Item $ScriptDir).Parent.FullName

$ValuesFile = "$RepoRoot\environments\hackathon\gateway-values.yaml"
$TemplateFile = "$ScriptDir\virtualservice.template.yaml"

if (-Not (Test-Path $ValuesFile)) {
    Write-Error "Cannot find gateway values file at $ValuesFile"
    exit 1
}

$content = Get-Content $ValuesFile -Raw

$GatewayName = ""
$GatewayNamespace = ""
$GatewayHost = ""

if ($content -match 'name:\s*"([^"]+)"') { $GatewayName = $Matches[1] }
if ($content -match 'namespace:\s*"([^"]+)"') { $GatewayNamespace = $Matches[1] }
if ($content -match 'host:\s*"([^"]+)"') { $GatewayHost = $Matches[1] }

$templateContent = Get-Content $TemplateFile -Raw
$renderedContent = $templateContent -replace '\$\{GATEWAY_NAME\}', $GatewayName `
                                    -replace '\$\{GATEWAY_NAMESPACE\}', $GatewayNamespace `
                                    -replace '\$\{GATEWAY_HOST\}', $GatewayHost

$renderedFile = "$ScriptDir\virtualservice.yaml"
$renderedContent | Set-Content $renderedFile

Write-Host "Rendered VirtualService manifest:"
Get-Content $renderedFile

Write-Host "`nRunning validation (dry-run) against cluster..."
kubectl apply -f $renderedFile --dry-run=client

Write-Host "Validation successful."
