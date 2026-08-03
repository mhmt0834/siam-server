[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [Parameter(Mandatory = $true)][string]$RestaurantName,
    [Parameter(Mandatory = $true)][string]$Slogan,
    [Parameter(Mandatory = $true)][string]$DCloudAppId,
    [Parameter(Mandatory = $true)][string]$WechatAppId,
    [Parameter(Mandatory = $true)][int]$DefaultShopId,
    [Parameter(Mandatory = $true)][string]$ApiBaseUrl,
    [Parameter(Mandatory = $true)][string]$RequestDomain,
    [string]$MapKey = '',
    [string]$HealthUrl = '',
    [string]$HBuilderCli = $env:HBUILDERX_CLI,
    [string]$AdminNodeBin = '',
    [string]$MerchantNodeBin = '',
    [switch]$EnableLocation,
    [switch]$EnableWechatPay,
    [switch]$MerchantApproved,
    [switch]$MerchantPaymentConfirmed,
    [switch]$ApplyConfiguration,
    [switch]$Build
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$root = [System.IO.Path]::GetFullPath($ProjectRoot)
if ($ApplyConfiguration -and -not $MerchantApproved) {
    throw 'MerchantApproved is required before writing merchant-specific values.'
}
if ($EnableWechatPay -and -not $MerchantPaymentConfirmed) {
    throw 'MerchantPaymentConfirmed is required before enabling WeChat Pay.'
}

$configArgs = @{
    ProjectRoot = $root
    RestaurantName = $RestaurantName
    Slogan = $Slogan
    DCloudAppId = $DCloudAppId
    WechatAppId = $WechatAppId
    DefaultShopId = $DefaultShopId
    ApiBaseUrl = $ApiBaseUrl
    RequestDomain = $RequestDomain
    MapKey = $MapKey
    EnableLocation = [bool]$EnableLocation
    EnableWechatPay = [bool]$EnableWechatPay
    ValidateOnly = -not [bool]$ApplyConfiguration
}

if ($ApplyConfiguration) {
    $config = Get-Content -LiteralPath (Join-Path $root 'restaurant-template.config.json') -Raw -Encoding utf8 | ConvertFrom-Json
    if ($config.templatePolicy.mode -eq 'reusable') {
        & (Join-Path $PSScriptRoot 'check-template-boundaries.ps1') -ProjectRoot $root
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}

& (Join-Path $PSScriptRoot 'apply_restaurant_config.ps1') @configArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not $ApplyConfiguration) {
    Write-Host 'Configuration validation passed. Re-run with -ApplyConfiguration -MerchantApproved on the merchant copy.' -ForegroundColor Green
    exit 0
}

& (Join-Path $PSScriptRoot 'check-secrets.ps1') -ProjectRoot $root
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($Build) {
    & (Join-Path $PSScriptRoot 'build-all.ps1') -ProjectRoot $root -HBuilderCli $HBuilderCli `
        -AdminNodeBin $AdminNodeBin -MerchantNodeBin $MerchantNodeBin
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $preflightArgs = @{
        ProjectRoot = $root
        RequireBuildArtifacts = $true
        PaymentConfirmed = [bool]$MerchantPaymentConfirmed
    }
    if (-not [string]::IsNullOrWhiteSpace($HealthUrl)) {
        $preflightArgs.HealthUrl = $HealthUrl
    }
    & (Join-Path $PSScriptRoot 'preflight-release.ps1') @preflightArgs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host 'Merchant delivery preparation passed. Upload only after the merchant approves the final preview.' -ForegroundColor Green
