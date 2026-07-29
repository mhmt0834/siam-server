[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [string]$HealthUrl = '',
    [switch]$RequireBuildArtifacts,
    [switch]$PaymentConfirmed
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$results = New-Object System.Collections.Generic.List[object]

function Add-Check([string]$Name, [bool]$Passed, [string]$Reason) {
    $results.Add([pscustomobject]@{
        Check = $Name
        Passed = $Passed
        Reason = $(if ($Passed) { '' } else { $Reason })
    })
}

$configPath = Join-Path $root 'restaurant-template.config.json'
$privacyPath = Join-Path $root 'privacy-data-map.json'
$manifestPath = Join-Path $root 'uniapp-siam-user\manifest.json'
$projectConfigPath = Join-Path $root 'uniapp-siam-user\project.config.json'
$vantCommonWxss = Join-Path $root 'uniapp-siam-user\wxcomponents\dist\vant\common\index.wxss'
$vantWxsUtils = Join-Path $root 'uniapp-siam-user\wxcomponents\dist\vant\wxs\utils.wxs'

Add-Check 'Template config' (Test-Path -LiteralPath $configPath -PathType Leaf) 'Missing restaurant-template.config.json'
Add-Check 'Privacy data map' (Test-Path -LiteralPath $privacyPath -PathType Leaf) 'Missing privacy-data-map.json'
Add-Check 'Vant shared styles' (Test-Path -LiteralPath $vantCommonWxss -PathType Leaf) 'Missing wxcomponents/dist/vant/common/index.wxss'
Add-Check 'Vant shared WXS' (Test-Path -LiteralPath $vantWxsUtils -PathType Leaf) 'Missing wxcomponents/dist/vant/wxs/utils.wxs'

if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding utf8 | ConvertFrom-Json
    Add-Check 'Merchant instance mode' ($config.templatePolicy.mode -eq 'merchant-instance') 'Run apply_restaurant_config.ps1 on a restaurant copy; never release the reusable template'
    Add-Check 'Merchant ownership marker' ($config.templatePolicy.miniProgramOwner -eq 'merchant') 'The mini-program owner must remain the merchant'
    Add-Check 'Restaurant shop ID' ([int]$config.restaurant.shopId -gt 0) 'Use the restaurant-specific backend shop ID'
    Add-Check 'DCloud AppID' (
        $config.release.dcloudAppId -match '^__UNI__[A-Za-z0-9]+$' -and
        $config.release.dcloudAppId -ne '__UNI__TEMPLATE'
    ) 'Use a project-specific DCloud AppID'
    Add-Check 'WeChat AppID' ($config.release.appId -match '^wx[A-Za-z0-9]{16}$') 'Use the merchant mini-program AppID'
    Add-Check 'HTTPS API' ($config.release.apiBaseUrl -match '^https://') 'API URL must use HTTPS'
    Add-Check 'Request domain' ($config.release.requestDomain -match '^https://') 'Request domain must use HTTPS'
    $locationEnabled = [bool]$config.features.location
    Add-Check 'Map key' ((-not $locationEnabled) -or -not [string]::IsNullOrWhiteSpace($config.release.mapKey)) 'Map key is required only when location is enabled'

    $paymentEnabled = [bool]$config.release.wechatPayEnabled
    Add-Check 'WeChat Pay confirmation' ((-not $paymentEnabled) -or $PaymentConfirmed) 'Merchant confirmation is required before enabling payment'
}

if ((Test-Path -LiteralPath $privacyPath -PathType Leaf)) {
    $privacy = Get-Content -LiteralPath $privacyPath -Raw -Encoding utf8 | ConvertFrom-Json
    $unconfirmed = @($privacy.features | Where-Object { $_.enabled -and -not $_.merchantConfirmed })
    Add-Check 'Privacy confirmation' ($unconfirmed.Count -eq 0) ('Unconfirmed: ' + (($unconfirmed.name) -join ', '))
}

if ((Test-Path -LiteralPath $manifestPath) -and (Test-Path -LiteralPath $projectConfigPath) -and $config) {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8
    $projectConfig = Get-Content -LiteralPath $projectConfigPath -Raw -Encoding utf8 | ConvertFrom-Json
    Add-Check 'WeChat AppID injection' ($projectConfig.appid -eq $config.release.appId) 'project.config.json does not match template config'
    Add-Check 'DCloud AppID injection' ($manifest -match [regex]::Escape('"' + $config.release.dcloudAppId + '"')) 'manifest.json does not match template config'
}

$miniProgramDist = Join-Path $root 'uniapp-siam-user\unpackage\dist\dev\mp-weixin'
if (Test-Path -LiteralPath $miniProgramDist -PathType Container) {
    $bytes = (Get-ChildItem -LiteralPath $miniProgramDist -Recurse -File | Measure-Object Length -Sum).Sum
    Add-Check 'Mini-program package size' ($bytes -le 2MB) ('Current size: ' + [math]::Round($bytes / 1MB, 2) + ' MB; preflight limit: 2 MB')

    $missingWxssImports = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $miniProgramDist -Recurse -File -Filter '*.wxss' | ForEach-Object {
        $wxssFile = $_
        $content = [System.IO.File]::ReadAllText($wxssFile.FullName, [System.Text.Encoding]::UTF8)
        foreach ($match in [regex]::Matches($content, '@import\s+["'']([^"'']+)["'']')) {
            $reference = $match.Groups[1].Value
            if ($reference.StartsWith('/')) {
                $target = Join-Path $miniProgramDist $reference.TrimStart('/')
            } else {
                $target = Join-Path $wxssFile.DirectoryName $reference
            }
            if (-not (Test-Path -LiteralPath ([System.IO.Path]::GetFullPath($target)) -PathType Leaf)) {
                $missingWxssImports.Add($wxssFile.Name + ' -> ' + $reference)
            }
        }
    }
    Add-Check 'WXSS import dependencies' ($missingWxssImports.Count -eq 0) ('Missing imports: ' + ($missingWxssImports -join ', '))

    & (Join-Path $PSScriptRoot 'check-mini-program-dependencies.ps1') -MiniProgramRoot $miniProgramDist -Quiet
    Add-Check 'Mini-program dependency scan' ($LASTEXITCODE -eq 0) 'Missing WXML, WXSS, WXS, JS, or component dependency'
} elseif ($RequireBuildArtifacts) {
    Add-Check 'Mini-program build output' $false 'Run scripts/build-all.ps1 first'
}

if (-not [string]::IsNullOrWhiteSpace($HealthUrl)) {
    try {
        $health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 10
        Add-Check 'Service health' ($health.status -eq 'UP') 'Health endpoint did not return UP'
    } catch {
        Add-Check 'Service health' $false $_.Exception.Message
    }
}

& (Join-Path $PSScriptRoot 'check-secrets.ps1') -ProjectRoot $root -Quiet
Add-Check 'Secret scan' ($LASTEXITCODE -eq 0) 'Potential secret, certificate, or private key found'

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Passed })
if ($failed.Count -gt 0) {
    Write-Host ("Release preflight failed: {0} check(s)." -f $failed.Count) -ForegroundColor Red
    exit 2
}

Write-Host 'Release preflight passed.' -ForegroundColor Green
exit 0
