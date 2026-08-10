param(
    [string]$ProjectPath = '',
    [int]$IdePort = 9420,
    [int]$AutomationPort = 9421
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $skillRoot = Split-Path -Parent $PSScriptRoot
    $repoRoot = (Resolve-Path (Join-Path $skillRoot '..\..\..')).Path
    $ProjectPath = Join-Path $repoRoot 'uniapp-siam-user\unpackage\dist\dev\mp-weixin'
}

$resolvedProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$projectConfig = Join-Path $resolvedProject 'project.config.json'
if (-not (Test-Path -LiteralPath $projectConfig)) {
    throw "Generated WeChat project is missing project.config.json: $projectConfig"
}

$installRoots = @(${env:ProgramFiles(x86)}, $env:ProgramFiles) | Where-Object { $_ }
$cli = $installRoots | ForEach-Object {
    $tencentRoot = Join-Path $_ 'Tencent'
    if (Test-Path -LiteralPath $tencentRoot) {
        Get-ChildItem -LiteralPath $tencentRoot -Filter 'cli.bat' -File -Recurse -ErrorAction SilentlyContinue
    }
} | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.Directory.FullName 'wechatdevtools.exe')
} | Select-Object -First 1 -ExpandProperty FullName
if (-not $cli) {
    throw 'WeChat Developer Tools cli.bat was not found.'
}

& $cli auto --project $resolvedProject --port $IdePort --auto-port $AutomationPort --trust-project --lang zh --disable-gpu
if ($LASTEXITCODE -ne 0) {
    throw "WeChat Developer Tools failed with exit code $LASTEXITCODE"
}

Write-Output "Developer Tools ready; IDE port=$IdePort; automation port=$AutomationPort"
