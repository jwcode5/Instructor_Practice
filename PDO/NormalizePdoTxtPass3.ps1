$path = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
if (-not (Test-Path $path)) { throw "File not found: $path" }

$lines = Get-Content -Path $path -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]

$seenFirstHeader = @{
    1 = $false
    2 = $false
    3 = $false
    4 = $false
}

foreach ($line in $lines) {
    $x = $line

    # Normalize leftover markers like A'I / B'I / C'I / D'I and quoted variants.
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’]I(?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’][!frt1:](?:[\''`’])?(?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])\.(?=\S)', '$1. ')

    # Convert remaining leading numeric option labels (1..4) to A..D,
    # but keep the first true question headers for 1,2,3,4.
    if ($x -match '^\s*([1-4])\.\s+(.*)$') {
        $n = [int]$matches[1]

        if (-not $seenFirstHeader[$n]) {
            $seenFirstHeader[$n] = $true
        } else {
            $letter = switch ($n) { 1 {'A'} 2 {'B'} 3 {'C'} 4 {'D'} }
            $x = [regex]::Replace($x, '^\s*[1-4]\.\s+', "$letter. ")
        }
    }

    $out.Add($x)
}

$out | Set-Content -Path $path -Encoding UTF8
Write-Output "Third pass complete: $path"
