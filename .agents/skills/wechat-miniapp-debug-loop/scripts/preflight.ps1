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

$gitRoot = (& git -C $ProjectRoot rev-parse --show-toplevel 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitRoot)) {
    throw "ProjectRoot is not a Git repository: $ProjectRoot"
}

$miniRoot = Join-Path $gitRoot "uniapp-siam-user"
$manifestPath = Join-Path $miniRoot "manifest.json"
$sourceProjectConfig = Join-Path $miniRoot "project.config.json"
$generatedRoot = Join-Path $miniRoot "unpackage\dist\dev\mp-weixin"
$generatedConfig = Join-Path $generatedRoot "project.config.json"

function Test-LocalPort([int]$Port) {
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $task = $client.ConnectAsync("127.0.0.1", $Port)
        $connected = $task.Wait(800) -and $client.Connected
        $client.Dispose()
        return $connected
    } catch {
        return $false
    }
}

function Test-ConfiguredAppId([string]$Path, [switch]$JsonWithComments) {
    if (-not (Test-Path -LiteralPath $Path)) { return "missing-file" }
    try {
        $raw = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path
        if ($JsonWithComments) {
            $match = [regex]::Match($raw, '"mp-weixin"\s*:\s*\{.*?"appid"\s*:\s*"([^"]*)"', 'Singleline')
            if (-not $match.Success) { return "missing" }
            $value = $match.Groups[1].Value
        } else {
            $value = ($raw | ConvertFrom-Json).appid
        }
        if ([string]::IsNullOrWhiteSpace($value)) { return "missing" }
        return "configured"
    } catch {
        return "parse-error"
    }
}

$status = @(& git -C $gitRoot status --short)
$manifestRelative = "uniapp-siam-user/manifest.json"
$manifestDirty = @($status | Where-Object { $_ -match 'uniapp-siam-user[/\\]manifest\.json$' }).Count -gt 0
$manifestHash = if (Test-Path -LiteralPath $manifestPath) { (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash } else { "missing" }

$result = [ordered]@{
    projectRoot = $gitRoot
    branch = (& git -C $gitRoot branch --show-current).Trim()
    commit = (& git -C $gitRoot rev-parse HEAD).Trim()
    dirtyFiles = $status
    protectedManifest = [ordered]@{
        path = $manifestRelative
        dirty = $manifestDirty
        sha256 = $manifestHash
    }
    miniProgram = [ordered]@{
        source = $miniRoot
        generated = $generatedRoot
        manifestAppId = Test-ConfiguredAppId -Path $manifestPath -JsonWithComments
        sourceProjectConfigAppId = Test-ConfiguredAppId -Path $sourceProjectConfig
        generatedAppId = Test-ConfiguredAppId -Path $generatedConfig
    }
    services = [ordered]@{
        backend9200 = Test-LocalPort 9200
        mysql3306 = Test-LocalPort 3306
        redis6379 = Test-LocalPort 6379
        mongodb27017 = Test-LocalPort 27017
    }
    windows = [ordered]@{
        hbuilderx = @((Get-Process HBuilderX -ErrorAction SilentlyContinue)).Count -gt 0
        wechatDeveloperTools = @((Get-Process wechatdevtools -ErrorAction SilentlyContinue)).Count -gt 0
    }
}

$result | ConvertTo-Json -Depth 6
