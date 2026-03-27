$target = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$backup = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.preclean.bak.txt'

if (-not (Test-Path $backup)) { throw "Backup not found: $backup" }
Copy-Item -Path $backup -Destination $target -Force

$lines = Get-Content -Path $target -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]

$prevNonEmpty = ''

function NormalizeMarkers([string]$x) {
    # Uppercase option markers only; avoid normal words like "by".
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[Yy](?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’][!frt1:\"](?:[\''`’])?(?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])-[rt](?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])0-r(?=\s|\.)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])\[Y(?=\s|\.)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[it](?=\s)', '$1.')

    # Ensure spacing after label punctuation.
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])\.(?=\S)', '$1. ')
    return $x
}

foreach ($line in $lines) {
    $x = $line

    # Remove separator and debris-only lines.
    if ($x -match '^\s*[_\-]{3,}\s*$') { continue }
    if ($x -match '^\s*[\*�]+\s*$') { continue }

    $x = NormalizeMarkers $x

    # Convert leading numeric options (1..4) to A..D only when likely option lines.
    if ($x -match '^\s*([1-4])\.\s+(.*)$') {
        $n = [int]$matches[1]
        $rest = $matches[2]

        $hasOtherOptionSameLine = $rest -match '(?<![A-Z0-9])[BCD](?:\.|\s)'
        $afterQuestionStem = $prevNonEmpty -match '[:?]\s*$'
        $looksLikeHeader = $rest -match '[:?]\s*$'

        if ((-not $looksLikeHeader) -and ($hasOtherOptionSameLine -or $afterQuestionStem)) {
            $letter = switch ($n) { 1 {'A'} 2 {'B'} 3 {'C'} 4 {'D'} }
            $x = [regex]::Replace($x, '^\s*[1-4]\.\s+', "$letter. ")
        }
    }

    $x = [regex]::Replace($x, '\s{2,}', ' ').TrimEnd()
    $out.Add($x)

    if ($x.Trim().Length -gt 0) { $prevNonEmpty = $x.Trim() }
}

$out | Set-Content -Path $target -Encoding UTF8
Write-Output "Restored from backup and normalized: $target"
