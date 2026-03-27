$path = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$backup = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.preclean.bak.txt'

if (-not (Test-Path $path)) { throw "File not found: $path" }
Copy-Item -Path $path -Destination $backup -Force

$lines = Get-Content -Path $path -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]

function Normalize-OptionMarkers([string]$line) {
    $x = $line
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[Yy](?=\s)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’][!frt1:\"](?=\s)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’]!(?=\s)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])-[rt](?=\s)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])!(?=\s)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])0-r(?=\s)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])\[Y(?=\s|\.)', 'D.')
    return $x
}

foreach ($line in $lines) {
    if ($line -match '^\s*[_\-]{3,}\s*$') { continue }
    if ($line -match '^\s*[\*�]+\s*$') { continue }

    $x = Normalize-OptionMarkers $line

    if ($x -match '^\s*([1-4])\.\s+(.*)$') {
        $n = [int]$matches[1]
        $rest = $matches[2]
        if ($rest -notmatch '[:?]\s*$') {
            $letter = switch ($n) { 1 {'A'} 2 {'B'} 3 {'C'} 4 {'D'} }
            $x = [regex]::Replace($x, '^\s*[1-4]\.\s+', "$letter. ")
        }
    }

    $x = [regex]::Replace($x, '\s{2,}', ' ').TrimEnd()
    $out.Add($x)
}

$out | Set-Content -Path $path -Encoding UTF8

Write-Output "Backup: $backup"
Write-Output "Cleaned: $path"
