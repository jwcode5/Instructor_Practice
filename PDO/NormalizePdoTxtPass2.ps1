$path = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
if (-not (Test-Path $path)) { throw "File not found: $path" }

$lines = Get-Content -Path $path -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
    $x = $line

    # AY/BY/CY/DY variants (including mixed case like cY)
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-Da-d])[Yy](?=\s|\.)', { param($m) ($m.Groups[1].Value.ToUpper() + '.') })

    # Markers like B'f, B'f', C-r, A'I, A'!, A't, etc.
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-Da-d])[\''`’][!frt1:](?:[\''`’])?(?=\s|\.)', { param($m) ($m.Groups[1].Value.ToUpper() + '.') })
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-Da-d])-[rt](?=\s|\.)', { param($m) ($m.Groups[1].Value.ToUpper() + '.') })

    # OCR substitutions for D
    $x = [regex]::Replace($x, '(?<![A-Z0-9])0-r(?=\s|\.)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])\[Y(?=\s|\.)', 'D.')

    # Ensure spacing after label
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])\.(?=\S)', '$1. ')

    $out.Add($x)
}

$out | Set-Content -Path $path -Encoding UTF8
Write-Output "Second pass complete: $path"
