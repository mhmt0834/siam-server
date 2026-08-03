[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [string]$HBuilderCli = $env:HBUILDERX_CLI,
    [string]$NpmCommand = 'npm.cmd',
    [string]$NodeBin = '',
    [string]$AdminNodeBin = '',
    [string]$MerchantNodeBin = '',
    [switch]$RunPreflight
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$adminRoot = Join-Path $root 'vue-siam-admin'
$merchantRoot = Join-Path $root 'vue-siam-shop'
$miniProgramRoot = Join-Path $root 'uniapp-siam-user'

if (-not (Test-Path -LiteralPath (Join-Path $adminRoot 'package.json'))) {
    throw 'Admin project not found.'
}
if (-not (Test-Path -LiteralPath (Join-Path $merchantRoot 'package.json'))) {
    throw 'Merchant project not found.'
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

if ([string]::IsNullOrWhiteSpace($AdminNodeBin)) {
    $bundledNode = Join-Path (Split-Path -Parent $HBuilderCli) 'plugins\node'
    if (Test-Path -LiteralPath (Join-Path $bundledNode 'node.exe') -PathType Leaf) {
        $AdminNodeBin = $bundledNode
    } else {
        $AdminNodeBin = $NodeBin
    }
}
if ([string]::IsNullOrWhiteSpace($MerchantNodeBin)) {
    $MerchantNodeBin = $NodeBin
}

function Invoke-FrontendBuild {
    param(
        [string]$FrontendRoot,
        [string]$RuntimeBin,
        [string]$DisplayName
    )

    $nodeExecutable = 'node'
    if (-not [string]::IsNullOrWhiteSpace($RuntimeBin)) {
        $candidate = Join-Path $RuntimeBin 'node.exe'
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "$DisplayName Node runtime not found: $candidate"
        }
        $nodeExecutable = $candidate
    }

    $previousNodeOptions = $env:NODE_OPTIONS
    $nodeVersion = (& $nodeExecutable --version).TrimStart('v')
    $nodeMajor = [int]($nodeVersion.Split('.')[0])
    try {
        $env:NODE_OPTIONS = $(if ($nodeMajor -ge 17) { '--openssl-legacy-provider' } else { $null })
        Push-Location $FrontendRoot
        & $nodeExecutable (Join-Path $PSScriptRoot 'run-webpack-build.js')
        if ($LASTEXITCODE -ne 0) {
            throw "$DisplayName production build failed."
        }
    } finally {
        Pop-Location
        $env:NODE_OPTIONS = $previousNodeOptions
    }
}

Invoke-FrontendBuild -FrontendRoot $adminRoot -RuntimeBin $AdminNodeBin -DisplayName 'Admin'
Invoke-FrontendBuild -FrontendRoot $merchantRoot -RuntimeBin $MerchantNodeBin -DisplayName 'Merchant'

$hbuilderOutput = & $HBuilderCli launch mp-weixin --project $miniProgramRoot --compile true --continue-on-error false 2>&1
$hbuilderExitCode = $LASTEXITCODE
$hbuilderOutput | ForEach-Object { Write-Host $_ }
$hbuilderText = $hbuilderOutput -join [Environment]::NewLine
if ($hbuilderExitCode -ne 0 -or $hbuilderText -match '未检测到已打开的HBuilderX') {
    throw 'Mini-program build failed.'
}

if ($RunPreflight) {
    & (Join-Path $PSScriptRoot 'preflight-release.ps1') -ProjectRoot $root -RequireBuildArtifacts
    exit $LASTEXITCODE
}

Write-Host 'Admin, merchant, and mini-program builds completed.' -ForegroundColor Green
