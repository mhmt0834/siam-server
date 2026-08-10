[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
} else {
    $ProjectRoot = (Resolve-Path $ProjectRoot).Path
}

$manifestPath = Join-Path $ProjectRoot "uniapp-siam-user\manifest.json"
$generatedConfigPath = Join-Path $ProjectRoot "uniapp-siam-user\unpackage\dist\dev\mp-weixin\project.config.json"
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Missing manifest: $manifestPath" }
if (-not (Test-Path -LiteralPath $generatedConfigPath)) { throw "Compile the mini-program first: $generatedConfigPath" }

$manifestHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash
$manifestRaw = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath
$appIdMatch = [regex]::Match($manifestRaw, '"mp-weixin"\s*:\s*\{.*?"appid"\s*:\s*"([^"]*)"', 'Singleline')
if (-not $appIdMatch.Success -or $appIdMatch.Groups[1].Value -notmatch '^wx[A-Za-z0-9]{16}$') {
    throw "mp-weixin AppID is missing or invalid in the protected manifest"
}

$generatedRaw = Get-Content -Raw -Encoding UTF8 -LiteralPath $generatedConfigPath
$generatedMatch = [regex]::Match($generatedRaw, '"appid"\s*:\s*"([^"]*)"')
if (-not $generatedMatch.Success) { throw "Generated project.config.json has no appid field" }

if ($generatedMatch.Groups[1].Value -eq $appIdMatch.Groups[1].Value) {
    Write-Output "generated_appid=already-configured"
} elseif ($PSCmdlet.ShouldProcess($generatedConfigPath, "copy configured AppID from protected manifest")) {
    $replacement = '"appid": "' + $appIdMatch.Groups[1].Value + '"'
    $updated = [regex]::Replace($generatedRaw, '"appid"\s*:\s*"[^"]*"', $replacement, 1)
    [System.IO.File]::WriteAllText($generatedConfigPath, $updated, [System.Text.UTF8Encoding]::new($false))
    Write-Output "generated_appid=configured"
}

$manifestHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash
if ($manifestHashAfter -ne $manifestHashBefore) {
    throw "Protected manifest changed unexpectedly"
}
Write-Output "protected_manifest=unchanged"
