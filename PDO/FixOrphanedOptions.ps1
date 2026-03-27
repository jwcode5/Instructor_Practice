# FixOrphanedOptions.ps1
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$lines = @(Get-Content $filePath -Encoding UTF8)
$output = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # If line starts with question marker, it's a question
    if ($line -match '^\d+\.\s+\w') {
        $output += $line
        continue
    }
    
    # If line is blank or separator
    if ($line -match '^\s*$' -or $line -match '^_{2,}') {
        $output += $line
        continue
    }
    
    # If line already has proper marker, keep it
    if ($line -match '^[A-D]\.' -or $line -match '^\s+[A-D]\.') {
        # Trim leading spaces from option lines
        $trimmed = $line -replace '^\s+', ''
        if ($trimmed -match '^[A-D]\.') {
            $output += $trimmed
        } else {
            $output += $line
        }
        continue
    }
    
    # If line starts with numeric marker (OCR artifact), convert to letter
    if ($line -match '^\s*(\d+)\.\s+(.+)$') {
        $match = [regex]::Match($line, '^\s*(\d+)\.\s+(.+)$')
        $num = [int]$match.Groups[1].Value
        $content = $match.Groups[2].Value
        
        # Convert 1->A, 2->B, 3->C, 4->D
        $labels = @('A.', 'B.', 'C.', 'D.')
        if ($num -ge 1 -and $num -le 4) {
            $output += "$($labels[$num - 1]) $content"
        } else {
            $output += $line
        }
        continue
    }
    
    # If line has text but no marker and looks like an option (lowercase start)
    if ($line -match '^[a-z].{3,}' -and $line -notmatch '^\s+of\s+') {
        # Check if previous non-empty line was a question
        $prevQ = -1
        for ($j = $i - 1; $j -ge 0; $j--) {
            if ($lines[$j] -match '^\s*$') { continue }
            if ($lines[$j] -match '^\d+\.') { $prevQ = 1; break }
            if ($lines[$j] -match '^[A-D]\.') { break }
        }
        
        # If we found the question start, try to guess which option this is
        if ($prevQ -eq 1) {
            # Count how many options we already have
            $optCount = 0
            for ($j = $i - 1; $j -ge 0; $j--) {
                if ($lines[$j] -match '^\d+\.') { break }
                if ($lines[$j] -match '^[A-D]\.') { $optCount++ }
            }
            
            if ($optCount -lt 4) {
                $labels = @('A.', 'B.', 'C.', 'D.')
                $output += "$($labels[$optCount]) $line"
            } else {
                $output += $line
            }
        } else {
            $output += $line
        }
        continue
    }
    
    $output += $line
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Fixed orphaned options"
