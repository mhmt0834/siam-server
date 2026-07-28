[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Quiet
)

$root = [System.IO.Path]::GetFullPath($ProjectRoot)
$excludedDirectories = @(
    '.git', '.idea', 'node_modules', 'target', 'unpackage',
    'dist', 'archive', 'logs', 'coverage'
)
$excludedNames = @(
    '.env.example',
    'application-local.example.yml',
    'Caddyfile.template'
)
$credentialExtensions = @('.key', '.pem', '.p12', '.pfx')
$quotedAssignmentPattern = '(?i)(appsecret|app_secret|access[_-]?key[_-]?secret|mch[_-]?key|private[_-]?key|password|secret)\s*[:=]\s*["'']([A-Za-z0-9+/_=.:-]{12,})["'']'
$configAssignmentPattern = '(?i)(appsecret|app_secret|access[_-]?key[_-]?secret|mch[_-]?key|private[_-]?key|password|secret)\s*[:=]\s*([A-Za-z0-9+/_=.:-]{12,})'
$configExtensions = @('.env', '.yml', '.yaml', '.json', '.properties', '.toml', '.config', '.xml')
$violations = New-Object System.Collections.Generic.List[object]

$rg = Get-Command 'rg' -ErrorAction SilentlyContinue
if ($rg) {
    $globArgs = @()
    foreach ($directory in $excludedDirectories) {
        $globArgs += @('-g', "!**/$directory/**")
    }
    foreach ($name in $excludedNames + @('application-local.yml')) {
        $globArgs += @('-g', "!**/$name")
    }

    Push-Location $root
    try {
        $relativeFiles = @(& $rg.Source --files @globArgs)
        foreach ($relative in $relativeFiles) {
            if ($credentialExtensions -contains [System.IO.Path]::GetExtension($relative).ToLowerInvariant()) {
                $violations.Add([pscustomobject]@{
                    File = $relative
                    Line = 0
                    Field = 'credential file'
                })
            }
        }

        $literalMatches = @(& $rg.Source --pcre2 -l $quotedAssignmentPattern @globArgs .)
        $privateKeyMatches = @(& $rg.Source -l -e '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' @globArgs .)
        $configGlobs = @()
        foreach ($extension in $configExtensions) {
            $configGlobs += @('-g', ('*' + $extension))
        }
        $configMatches = @(& $rg.Source --pcre2 -l $configAssignmentPattern @globArgs @configGlobs .)

        foreach ($relative in @($literalMatches + $privateKeyMatches + $configMatches) | Sort-Object -Unique) {
            $violations.Add([pscustomobject]@{
                File = $relative
                Line = 0
                Field = 'hard-coded secret'
            })
        }
    } finally {
        Pop-Location
    }
} else {
    $files = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($root.Length).TrimStart('\')
        $parts = $relative -split '[\\/]'
        $isExcludedDirectory = @($parts | Where-Object { $excludedDirectories -contains $_ }).Count -gt 0
        if ($isExcludedDirectory -or $excludedNames -contains $file.Name -or $file.Name -eq 'application-local.yml') {
            continue
        }
        if ($credentialExtensions -contains $file.Extension.ToLowerInvariant()) {
            $violations.Add([pscustomobject]@{
                File = $relative
                Line = 0
                Field = 'credential file'
            })
            continue
        }
        if ($file.Length -gt 2MB) {
            continue
        }
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $hasQuotedSecret = [regex]::IsMatch($content, $quotedAssignmentPattern)
        $hasConfigSecret = ($configExtensions -contains $file.Extension.ToLowerInvariant()) -and [regex]::IsMatch($content, $configAssignmentPattern)
        $hasPrivateKey = $content -match '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
        if ($hasQuotedSecret -or $hasConfigSecret -or $hasPrivateKey) {
            $violations.Add([pscustomobject]@{
                File = $relative
                Line = 0
                Field = 'hard-coded secret'
            })
        }
    }
}

if ($violations.Count -gt 0) {
    Write-Host 'Potential credential or certificate files found; secret values are not displayed:' -ForegroundColor Red
    $violations | Sort-Object File, Line | Format-Table -AutoSize
    exit 2
}

if (-not $Quiet) {
    Write-Host 'Secret scan passed.' -ForegroundColor Green
}
exit 0
