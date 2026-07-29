[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$RestaurantName,
    [Parameter(Mandatory = $true)][string]$Slogan,
    [Parameter(Mandatory = $true)][string]$DCloudAppId,
    [Parameter(Mandatory = $true)][string]$WechatAppId,
    [Parameter(Mandatory = $true)][int]$DefaultShopId,
    [Parameter(Mandatory = $true)][string]$ApiBaseUrl,
    [Parameter(Mandatory = $true)][string]$RequestDomain,
    [string]$MapKey = '',
    [switch]$EnableLocation,
    [switch]$EnableWechatPay,
    [switch]$ValidateOnly
)

$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$required = @(
    'restaurant-template.config.json',
    'privacy-data-map.json',
    'uniapp-siam-user\manifest.json',
    'uniapp-siam-user\project.config.json',
    'uniapp-siam-user\utils\brand-config.js',
    'uniapp-siam-user\utils\global-config.js',
    'uniapp-siam-user\utils\gaode-libs\config.js'
)

foreach ($relative in $required) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing template file: $relative"
    }
}
if ($WechatAppId -notmatch '^wx[A-Za-z0-9]{16}$') {
    throw 'WechatAppId format is invalid.'
}
if ($DCloudAppId -notmatch '^__UNI__[A-Za-z0-9]+$' -or $DCloudAppId -eq '__UNI__TEMPLATE') {
    throw 'DCloudAppId format is invalid.'
}
if ($DefaultShopId -le 0) {
    throw 'DefaultShopId must be a positive integer.'
}
if ($ApiBaseUrl -notmatch '^https://') {
    throw 'ApiBaseUrl must use HTTPS.'
}
if ($RequestDomain -notmatch '^https://') {
    throw 'RequestDomain must use HTTPS.'
}
if ($EnableLocation -and [string]::IsNullOrWhiteSpace($MapKey)) {
    throw 'MapKey is required only when EnableLocation is used.'
}

$summary = [ordered]@{
    RestaurantName = $RestaurantName
    Slogan = $Slogan
    DCloudAppId = $DCloudAppId
    WechatAppId = $WechatAppId
    DefaultShopId = $DefaultShopId
    ApiBaseUrl = $ApiBaseUrl.TrimEnd('/')
    RequestDomain = $RequestDomain.TrimEnd('/')
    LocationEnabled = [bool]$EnableLocation
    WechatPayEnabled = [bool]$EnableWechatPay
}
if ($ValidateOnly) {
    $summary | ConvertTo-Json
    exit 0
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
function Read-Utf8([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}
function Write-Utf8([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}
function Escape-Js([string]$Value) {
    return $Value.Replace('\', '\\').Replace("'", "\'")
}

$configPath = Join-Path $root 'restaurant-template.config.json'
$config = (Read-Utf8 $configPath) | ConvertFrom-Json
$config.templatePolicy.mode = 'merchant-instance'
$config.restaurant.name = $RestaurantName
$config.restaurant.slogan = $Slogan
$config.restaurant.shopId = $DefaultShopId
$config.features.location = [bool]$EnableLocation
$config.features.onlinePayment = [bool]$EnableWechatPay
$config.release.dcloudAppId = $DCloudAppId
$config.release.appId = $WechatAppId
$config.release.apiBaseUrl = $ApiBaseUrl.TrimEnd('/')
$config.release.requestDomain = $RequestDomain.TrimEnd('/')
$config.release.mapKey = $(if ($EnableLocation) { $MapKey } else { '' })
$config.release.wechatPayEnabled = [bool]$EnableWechatPay
Write-Utf8 $configPath ($config | ConvertTo-Json -Depth 10)

$privacyPath = Join-Path $root 'privacy-data-map.json'
$privacy = (Read-Utf8 $privacyPath) | ConvertFrom-Json
$privacy.merchantConfirmedAt = ''
foreach ($feature in $privacy.features) {
    $feature.merchantConfirmed = $false
    if ($feature.id -eq 'location_and_address') {
        $feature.enabled = [bool]$EnableLocation
    }
}
Write-Utf8 $privacyPath ($privacy | ConvertTo-Json -Depth 10)

$brandPath = Join-Path $root 'uniapp-siam-user\utils\brand-config.js'
$brand = Read-Utf8 $brandPath
$brand = $brand -replace "restaurantName:\s*'[^']*'", ("restaurantName: '" + (Escape-Js $RestaurantName) + "'")
$brand = $brand -replace "slogan:\s*'[^']*'", ("slogan: '" + (Escape-Js $Slogan) + "'")
$brand = $brand -replace "primary:\s*'[^']*'", ("primary: '" + $config.theme.primary + "'")
$brand = $brand -replace "accent:\s*'[^']*'", ("accent: '" + $config.theme.accent + "'")
$brand = $brand -replace "background:\s*'[^']*'", ("background: '" + $config.theme.background + "'")
$brand = $brand -replace "surface:\s*'[^']*'", ("surface: '" + $config.theme.surface + "'")
$brand = $brand -replace 'location:\s*(true|false)', ('location: ' + ([bool]$EnableLocation).ToString().ToLowerInvariant())
$brand = $brand -replace 'onlinePayment:\s*(true|false)', ('onlinePayment: ' + ([bool]$EnableWechatPay).ToString().ToLowerInvariant())
Write-Utf8 $brandPath $brand

$manifestPath = Join-Path $root 'uniapp-siam-user\manifest.json'
$manifest = Read-Utf8 $manifestPath
$manifest = [regex]::Replace($manifest, '("appid"\s*:\s*")[^"]*(")', ('$1' + $DCloudAppId + '$2'), 1)
$manifest = [regex]::Replace(
    $manifest,
    '("mp-weixin"\s*:\s*\{[\s\S]*?"appid"\s*:\s*")[^"]*(")',
    ('$1' + $WechatAppId + '$2'),
    [System.Text.RegularExpressions.RegexOptions]::None,
    [TimeSpan]::FromSeconds(2)
)
Write-Utf8 $manifestPath $manifest

$projectPath = Join-Path $root 'uniapp-siam-user\project.config.json'
$project = Read-Utf8 $projectPath
$project = [regex]::Replace($project, '("appid"\s*:\s*")[^"]*(")', ('$1' + $WechatAppId + '$2'), 1)
Write-Utf8 $projectPath $project

$globalPath = Join-Path $root 'uniapp-siam-user\utils\global-config.js'
$global = Read-Utf8 $globalPath
$global = [regex]::Replace(
    $global,
    "(?s)(#ifdef APP-PLUS\|\|MP-WEIXIN\|\|MP-ALIPAY.*?static baseUrl = ')[^']*(';)",
    ('$1' + $ApiBaseUrl.TrimEnd('/') + '$2')
)
$global = [regex]::Replace(
    $global,
    'static defaultShopId = (?:null|\d+);',
    ('static defaultShopId = ' + $DefaultShopId + ';'),
    1
)
Write-Utf8 $globalPath $global

$mapPath = Join-Path $root 'uniapp-siam-user\utils\gaode-libs\config.js'
$map = Read-Utf8 $mapPath
$effectiveMapKey = $(if ($EnableLocation) { $MapKey } else { '' })
$map = [regex]::Replace($map, 'return\s+"[^"]*"', ('return "' + $effectiveMapKey + '"'), 1)
Write-Utf8 $mapPath $map

$summary | ConvertTo-Json
