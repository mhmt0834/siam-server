[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MiniProgramRoot,
    [switch]$Quiet
)

$root = [System.IO.Path]::GetFullPath($MiniProgramRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw 'Mini-program build directory not found.'
}

$missing = New-Object System.Collections.Generic.List[object]

function Test-Reference([string]$SourceFile, [string]$Reference) {
    if ([string]::IsNullOrWhiteSpace($Reference)) {
        return $true
    }
    if ($Reference -match '^(plugin|ext|https?):' -or -not ($Reference.StartsWith('.') -or $Reference.StartsWith('/'))) {
        return $true
    }

    $clean = ($Reference -split '[?#]')[0]
    if ($clean.StartsWith('/')) {
        $base = Join-Path $root ($clean.TrimStart('/'))
    } else {
        $base = Join-Path (Split-Path -Parent $SourceFile) $clean
    }
    $base = [System.IO.Path]::GetFullPath($base)
    $candidates = @(
        $base,
        ($base + '.js'),
        ($base + '.json'),
        ($base + '.wxml'),
        ($base + '.wxss'),
        ($base + '.wxs'),
        (Join-Path $base 'index.js'),
        (Join-Path $base 'index.json'),
        (Join-Path $base 'index.wxml'),
        (Join-Path $base 'index.wxs')
    )
    $existing = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    return ($existing.Count -gt 0)
}

$textPatterns = @{
    '.wxss' = @('@import\s+["'']([^"'']+)["'']')
    '.wxml' = @('<(?:wxs|import|include)\b[^>]*\bsrc\s*=\s*["'']([^"'']+)["'']')
    '.wxs' = @('require\(\s*["'']([^"'']+)["'']\s*\)')
    '.js' = @('require\(\s*["'']([^"'']+)["'']\s*\)')
}

Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
    $file = $_
    $extension = $file.Extension.ToLowerInvariant()
    if ($textPatterns.ContainsKey($extension)) {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        foreach ($pattern in $textPatterns[$extension]) {
            foreach ($match in [regex]::Matches($content, $pattern)) {
                $reference = $match.Groups[1].Value
                if (-not (Test-Reference $file.FullName $reference)) {
                    $missing.Add([pscustomobject]@{
                        File = $file.FullName.Substring($root.Length).TrimStart('\')
                        Reference = $reference
                    })
                }
            }
        }
    }

    if ($extension -eq '.json') {
        try {
            $json = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            if ($json.usingComponents) {
                foreach ($property in $json.usingComponents.psobject.Properties) {
                    $reference = [string]$property.Value
                    if (-not (Test-Reference $file.FullName $reference)) {
                        $missing.Add([pscustomobject]@{
                            File = $file.FullName.Substring($root.Length).TrimStart('\')
                            Reference = $reference
                        })
                    }
                }
            }
        } catch {
            $missing.Add([pscustomobject]@{
                File = $file.FullName.Substring($root.Length).TrimStart('\')
                Reference = 'invalid JSON'
            })
        }
    }
}

if ($missing.Count -gt 0) {
    Write-Host 'Missing mini-program dependencies:' -ForegroundColor Red
    $missing | Sort-Object File, Reference -Unique | Format-Table -AutoSize
    exit 2
}

if (-not $Quiet) {
    Write-Host 'Mini-program dependency scan passed.' -ForegroundColor Green
}
exit 0
