# MasterCleanupScript.ps1 - One comprehensive, careful pass
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$lines = @(Get-Content $filePath -Encoding UTF8)
$output = @()
$i = 0

while ($i -lt $lines.Count) {
    $line = $lines[$i]
    
    # === SKIP SEPARATORS AND BLANKS ===
    if ($line -match '^\s*$' -or $line -match '^_+') {
        # Keep one blank line between questions, but not doubles
        if ($output.Count -gt 0 -and $output[-1] -notmatch '^\s*$') {
            $output += ''
        }
        $i++
        continue
    }
    
    # === QUESTION HEADER ===
    if ($line -match '^\d+\.\s+\w') {
        $output += $line
        $i++
        
        # === COLLECT OPTIONS FOR THIS QUESTION ===
        while ($i -lt $lines.Count) {
            $testLine = $lines[$i]
            
            # Stop at next question
            if ($testLine -match '^\d+\.\s+\w') {
                break
            }
            
            # Skip separators
            if ($testLine -match '^\s*$' -or $testLine -match '^_+') {
                $i++
                continue
            }
            
            # === NORMALIZE MARKERS FIRST ===
            $normalized = $testLine
            # Fix OCR marker corruption
            $normalized = $normalized -replace '\bAY\b', 'A.'
            $normalized = $normalized -replace '\bBY\b', 'B.'
            $normalized = $normalized -replace '\bCY\b', 'C.'
            $normalized = $normalized -replace '\bDY\b', 'D.'
            $normalized = $normalized -replace "A'!", 'A.'
            $normalized = $normalized -replace "A':", 'A.'
            $normalized = $normalized -replace "B'!", 'B.'
            $normalized = $normalized -replace "B':", 'B.'
            $normalized = $normalized -replace "C'!", 'C.'
            $normalized = $normalized -replace "C':", 'C.'
            $normalized = $normalized -replace "D'!", 'D.'
            $normalized = $normalized -replace "D':", 'D.'
            $normalized = $normalized -replace 'A-', 'A.'
            $normalized = $normalized -replace 'B-', 'B.'
            $normalized = $normalized -replace 'C-', 'C.'
            $normalized = $normalized -replace 'D-', 'D.'
            
            # === CHECK IF MULTI-OPTION LINE ===
            $optionMatches = [regex]::Matches($normalized, '[A-D]\.')
            if ($optionMatches.Count -ge 2) {
                # Multi-option line - split it
                # Handle numeric prefix conversion first
                $normalized = $normalized -replace '^\s*1\.(\s+[a-z])', 'A.$1'
                $normalized = $normalized -replace '\s{2,}2\.(\s+[a-z])', '  B.$1'
                $normalized = $normalized -replace '\s{2,}3\.(\s+[a-z])', '  C.$1'
                $normalized = $normalized -replace '\s{2,}4\.(\s+[a-z])', '  D.$1'
                
                # Now split by option markers
                $parts = $normalized -split '(?=[A-D]\.)'
                foreach ($part in $parts) {
                    $part = $part.Trim()
                    if ($part.Length -gt 2 -and $part -match '^[A-D]\.') {
                        $output += $part
                    }
                }
            } else {
                # Single option or regular line
                $output += $normalized
            }
            
            $i++
        }
    } else {
        # Non-question content
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0) {
            $output += $line
        }
        $i++
    }
}

# Remove trailing blanks
while ($output.Count -gt 0 -and $output[-1] -match '^\s*$') {
    $output = $output[0..($output.Count - 2)]
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Master cleanup complete. Lines: $($output.Count)"
