[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
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
$brandPath = Join-Path $root 'uniapp-siam-user\utils\brand-config.js'
$globalPath = Join-Path $root 'uniapp-siam-user\utils\global-config.js'
$mapPath = Join-Path $root 'uniapp-siam-user\utils\gaode-libs\config.js'

$config = Get-Content -LiteralPath $configPath -Raw -Encoding utf8 | ConvertFrom-Json
Add-Check 'Reusable mode' ($config.templatePolicy.mode -eq 'reusable') 'Template mode must be reusable'
Add-Check 'Merchant ownership' ($config.templatePolicy.miniProgramOwner -eq 'merchant') 'Mini-program ownership must remain with the merchant'
Add-Check 'Placeholder restaurant' (
    $config.restaurant.name -eq $config.templatePolicy.placeholderRestaurantName -and
    [string]::IsNullOrWhiteSpace($config.restaurant.logo) -and
    [string]::IsNullOrWhiteSpace($config.restaurant.phone) -and
    [string]::IsNullOrWhiteSpace($config.restaurant.address) -and
    [int]$config.restaurant.shopId -eq 0
) 'Restaurant identity or shop ID must not be synced back'
Add-Check 'Safe feature defaults' (
    -not [bool]$config.features.selfPickup -and
    -not [bool]$config.features.delivery -and
    -not [bool]$config.features.location -and
    -not [bool]$config.features.onlinePayment
) 'Pickup, delivery, location, and payment must default to disabled'
Add-Check 'Release placeholders' (
    $config.release.dcloudAppId -eq '__UNI__TEMPLATE' -and
    [string]::IsNullOrWhiteSpace($config.release.appId) -and
    [string]::IsNullOrWhiteSpace($config.release.mapKey) -and
    -not [bool]$config.release.wechatPayEnabled
) 'Per-merchant release values must remain placeholders'
$sharedInfrastructure = $config.templatePolicy.sharedInfrastructure
$sharedInfrastructurePassed = if ([bool]$sharedInfrastructure.approvedForTemplate) {
    $config.release.apiBaseUrl -match '^https://' -and
    $config.release.requestDomain -match '^https://' -and
    $config.release.apiBaseUrl -eq $sharedInfrastructure.apiBaseUrl -and
    $config.release.requestDomain -eq $sharedInfrastructure.requestDomain
} else {
    [string]::IsNullOrWhiteSpace($config.release.apiBaseUrl) -and
    [string]::IsNullOrWhiteSpace($config.release.requestDomain) -and
    [string]::IsNullOrWhiteSpace($sharedInfrastructure.apiBaseUrl) -and
    [string]::IsNullOrWhiteSpace($sharedInfrastructure.requestDomain)
}
Add-Check 'Shared API approval' $sharedInfrastructurePassed 'API URL and request domain require explicit shared-infrastructure approval'

$privacy = Get-Content -LiteralPath $privacyPath -Raw -Encoding utf8 | ConvertFrom-Json
$confirmed = @($privacy.features | Where-Object { $_.merchantConfirmed })
$location = @($privacy.features | Where-Object { $_.id -eq 'location_and_address' }) | Select-Object -First 1
Add-Check 'Privacy reset' (
    [string]::IsNullOrWhiteSpace($privacy.merchantConfirmedAt) -and
    $confirmed.Count -eq 0
) 'Merchant privacy confirmation must never be copied into the template'
Add-Check 'Location disabled' ($null -ne $location -and -not [bool]$location.enabled) 'Location must be disabled in the reusable template'

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8
Add-Check 'Manifest placeholder AppID' (
    $manifest -match '"appid"\s*:\s*"__UNI__TEMPLATE"' -and
    $manifest -match '"mp-weixin"\s*:\s*\{[\s\S]*?"appid"\s*:\s*""'
) 'Manifest AppIDs must be placeholders'
Add-Check 'Manifest map placeholders' (
    $manifest -notmatch '"(?:appkey_ios|appkey_android|securityJsCode)"\s*:\s*"[^"]+"' -and
    $manifest -notmatch '"key"\s*:\s*"[A-Fa-f0-9]{16,}"'
) 'Platform-specific map values must not be synced back'

$sourceManifests = @(
    Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'manifest.json' |
        Where-Object { $_.FullName -notmatch '[\\/](?:node_modules|unpackage|dist|target)[\\/]' }
)
$invalidManifestAppIds = New-Object System.Collections.Generic.List[string]
$manifestMapValues = New-Object System.Collections.Generic.List[string]
foreach ($sourceManifest in $sourceManifests) {
    $content = Get-Content -LiteralPath $sourceManifest.FullName -Raw -Encoding utf8
    $firstAppId = [regex]::Match($content, '"appid"\s*:\s*"([^"]*)"').Groups[1].Value
    if ($firstAppId -notmatch '^__UNI__[A-Z0-9_]*TEMPLATE$') {
        $invalidManifestAppIds.Add($sourceManifest.FullName)
    }
    if (
        $content -match '"(?:appkey_ios|appkey_android|securityJsCode)"\s*:\s*"[^"]+"' -or
        $content -match '"key"\s*:\s*"[A-Fa-f0-9]{16,}"'
    ) {
        $manifestMapValues.Add($sourceManifest.FullName)
    }
}
Add-Check 'Repository manifest placeholders' ($invalidManifestAppIds.Count -eq 0) 'Every source DCloud AppID must remain a template placeholder'
Add-Check 'Repository map placeholders' ($manifestMapValues.Count -eq 0) 'Map values must be empty in every source manifest'

$brand = Get-Content -LiteralPath $brandPath -Raw -Encoding utf8
$global = Get-Content -LiteralPath $globalPath -Raw -Encoding utf8
$map = Get-Content -LiteralPath $mapPath -Raw -Encoding utf8
Add-Check 'Frontend brand placeholder' (
    $brand -match ("restaurantName:\s*'" + [regex]::Escape([string]$config.templatePolicy.placeholderRestaurantName) + "'")
) 'Frontend restaurant identity must stay generic'
Add-Check 'Frontend shop placeholder' ($global -match 'static defaultShopId = null;') 'Frontend shop ID must stay empty'
Add-Check 'Frontend map placeholder' ($map -match 'return\s+""') 'Frontend map key must stay empty'

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Passed })
if ($failed.Count -gt 0) {
    Write-Host ("Template boundary check failed: {0} check(s)." -f $failed.Count) -ForegroundColor Red
    exit 2
}

Write-Host 'Template boundary check passed.' -ForegroundColor Green
exit 0
