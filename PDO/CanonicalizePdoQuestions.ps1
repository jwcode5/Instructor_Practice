$inPath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$outPath = $inPath
$reportPath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.validation_report.txt'

if (-not (Test-Path $inPath)) { throw "Input file not found: $inPath" }

$lines = Get-Content -Path $inPath -Encoding UTF8

function Clean-Line([string]$line) {
    $x = $line
    $x = [regex]::Replace($x, '\s{2,}', ' ')
    $x = $x.Trim()

    if ($x -match '^[_\-]{3,}$') { return '' }
    if ($x -match '^[\*�]+$') { return '' }

    # Normalize lingering markers
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[Yy](?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])[\''`’][!frt1:I:\"](?:[\''`’])?(?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])-[rt](?=\s|\.)', '$1.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])0-r(?=\s|\.)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])\[Y(?=\s|\.)', 'D.')
    $x = [regex]::Replace($x, '(?<![A-Z0-9])([A-D])\.(?=\S)', '$1. ')

    return $x.Trim()
}

$questions = New-Object System.Collections.Generic.List[object]
$current = $null
$lastOption = $null
$issues = New-Object System.Collections.Generic.List[string]

function New-Q([int]$num, [string]$text) {
    [PSCustomObject]@{
        Num = $num
        Text = $text
        A = ''
        B = ''
        C = ''
        D = ''
    }
}

function Append-OptionValue($q, [string]$letter, [string]$text) {
    if (-not $text) { return }
    switch ($letter) {
        'A' { if (-not $q.A) { $q.A = $text } elseif ($q.A -notlike "*$text*") { $q.A = ($q.A + ' ' + $text).Trim() } }
        'B' { if (-not $q.B) { $q.B = $text } elseif ($q.B -notlike "*$text*") { $q.B = ($q.B + ' ' + $text).Trim() } }
        'C' { if (-not $q.C) { $q.C = $text } elseif ($q.C -notlike "*$text*") { $q.C = ($q.C + ' ' + $text).Trim() } }
        'D' { if (-not $q.D) { $q.D = $text } elseif ($q.D -notlike "*$text*") { $q.D = ($q.D + ' ' + $text).Trim() } }
    }
}

foreach ($raw in $lines) {
    $line = Clean-Line $raw
    if (-not $line) { continue }

    # Explicit A./B./C./D. option line
    if ($line -match '^([A-D])\.\s+(.+)$') {
        if ($null -eq $current) {
            $issues.Add("Orphan option without question: $line")
            continue
        }
        $letter = $matches[1]
        $text = $matches[2].Trim()
        Append-OptionValue $current $letter $text
        $lastOption = $letter
        continue
    }

    # Numeric-prefixed line (can be question header or OCR-numbered option)
    if ($line -match '^(\d{1,3})\.\s+(.+)$') {
        $n = [int]$matches[1]
        $rest = $matches[2].Trim()

        $looksHeader = ($rest -match '[:?]\s*$')

        if ($null -eq $current) {
            $current = New-Q $n $rest
            $questions.Add($current)
            $lastOption = $null
            continue
        }

        # Start new question when clearly a header and progresses numbering
        if ($looksHeader -and $n -ge $current.Num) {
            $current = New-Q $n $rest
            $questions.Add($current)
            $lastOption = $null
            continue
        }

        # Otherwise treat as option line
        $letter = $null
        if ($n -ge 1 -and $n -le 4) {
            $letter = @('A','B','C','D')[$n-1]
        } else {
            # For 5..9 OCR shifts, place into first missing slot
            if (-not $current.A) { $letter = 'A' }
            elseif (-not $current.B) { $letter = 'B' }
            elseif (-not $current.C) { $letter = 'C' }
            elseif (-not $current.D) { $letter = 'D' }
            else { $letter = 'D' }
        }

        Append-OptionValue $current $letter $rest
        $lastOption = $letter
        continue
    }

    # Continuation text
    if ($null -eq $current) {
        $issues.Add("Orphan text before first question: $line")
        continue
    }

    if ($lastOption) {
        # append to current option
        switch ($lastOption) {
            'A' { $current.A = ($current.A + ' ' + $line).Trim() }
            'B' { $current.B = ($current.B + ' ' + $line).Trim() }
            'C' { $current.C = ($current.C + ' ' + $line).Trim() }
            'D' { $current.D = ($current.D + ' ' + $line).Trim() }
        }
    } else {
        $current.Text = ($current.Text + ' ' + $line).Trim()
    }
}

# Keep first occurrence of each question number in 1..387
$map = @{}
foreach ($q in $questions) {
    if ($q.Num -ge 1 -and $q.Num -le 387) {
        if (-not $map.ContainsKey($q.Num)) { $map[$q.Num] = $q }
    }
}

$final = New-Object System.Collections.Generic.List[object]
for ($i=1; $i -le 387; $i++) {
    if ($map.ContainsKey($i)) {
        $q = $map[$i]
    } else {
        $q = New-Q $i '[MISSING QUESTION TEXT]'
        $issues.Add("Missing question number $i")
    }

    foreach ($opt in 'A','B','C','D') {
        $val = $q.$opt
        if (-not $val) {
            $q.$opt = "[MISSING OPTION $opt]"
            $issues.Add("Q$i missing option $opt")
        }
    }
    $final.Add($q)
}

# Write canonical output
$sb = New-Object System.Text.StringBuilder
foreach ($q in $final) {
    [void]$sb.AppendLine("$($q.Num). $($q.Text)")
    [void]$sb.AppendLine("A. $($q.A)")
    [void]$sb.AppendLine("B. $($q.B)")
    [void]$sb.AppendLine("C. $($q.C)")
    [void]$sb.AppendLine("D. $($q.D)")
    [void]$sb.AppendLine()
}
$sb.ToString().TrimEnd() | Set-Content -Path $outPath -Encoding UTF8

# Write report
$rep = New-Object System.Text.StringBuilder
[void]$rep.AppendLine("Canonicalization Report")
[void]$rep.AppendLine("Questions emitted: 387")
[void]$rep.AppendLine("Total source question-like blocks: $($questions.Count)")
[void]$rep.AppendLine("Issues flagged: $($issues.Count)")
[void]$rep.AppendLine()
foreach ($i in $issues) { [void]$rep.AppendLine($i) }
$rep.ToString().TrimEnd() | Set-Content -Path $reportPath -Encoding UTF8

Write-Output "Wrote canonical file: $outPath"
Write-Output "Wrote report: $reportPath"
Write-Output "Issues: $($issues.Count)"