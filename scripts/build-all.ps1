[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [string]$HBuilderCli = $env:HBUILDERX_CLI,
    [string]$NpmCommand = 'npm.cmd',
    [string]$NodeBin = '',
    [switch]$RunPreflight
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$adminRoot = Join-Path $root 'vue-siam-admin'
$miniProgramRoot = Join-Path $root 'uniapp-siam-user'

if (-not (Test-Path -LiteralPath (Join-Path $adminRoot 'package.json'))) {
    throw 'Admin project not found.'
}
if (-not (Test-Path -LiteralPath (Join-Path $miniProgramRoot 'manifest.json'))) {
    throw 'Mini-program project not found.'
}

if ([string]::IsNullOrWhiteSpace($HBuilderCli)) {
    $command = Get-Command 'cli.exe' -ErrorAction SilentlyContinue
    if ($command) {
        $HBuilderCli = $command.Source
    }
}
if ([string]::IsNullOrWhiteSpace($HBuilderCli) -or -not (Test-Path -LiteralPath $HBuilderCli -PathType Leaf)) {
    throw 'HBuilderX cli.exe not found. Set HBUILDERX_CLI or pass -HBuilderCli.'
}

$previousNodeOptions = $env:NODE_OPTIONS
$previousPath = $env:Path
try {
    if ([string]::IsNullOrWhiteSpace($NodeBin)) {
        $bundledNode = Join-Path (Split-Path -Parent $HBuilderCli) 'plugins\node'
        if (Test-Path -LiteralPath (Join-Path $bundledNode 'node.exe') -PathType Leaf) {
            $NodeBin = $bundledNode
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($NodeBin)) {
        $env:Path = $NodeBin + [System.IO.Path]::PathSeparator + $env:Path
    }
    $env:NODE_OPTIONS = '--openssl-legacy-provider'
    Push-Location $adminRoot
    try {
        & $NpmCommand run build
        if ($LASTEXITCODE -ne 0) {
            throw 'Admin production build failed.'
        }
    } finally {
        Pop-Location
    }

    & $HBuilderCli launch mp-weixin --project $miniProgramRoot --compile true --continue-on-error false
    if ($LASTEXITCODE -ne 0) {
        throw 'Mini-program build failed.'
    }
} finally {
    $env:NODE_OPTIONS = $previousNodeOptions
    $env:Path = $previousPath
}

if ($RunPreflight) {
    & (Join-Path $PSScriptRoot 'preflight-release.ps1') -ProjectRoot $root -RequireBuildArtifacts
    exit $LASTEXITCODE
}

Write-Host 'Admin and mini-program builds completed.' -ForegroundColor Green
