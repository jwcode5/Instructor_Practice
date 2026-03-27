# AggressiveCleanPdo.ps1 - More thorough OCR cleanup

$filePath = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt"
$content = Get-Content $filePath -Raw -Encoding UTF8

# Step 1: Normalize all marker variants to exact format before splitting
# Handle all the weird OCR markers
$content = $content -replace "B'(?=[!\`'])", 'B.'
$content = $content -replace "C'(?=[!:\`'])", 'C.'
$content = $content -replace "D'(?=[!:\`'])", 'D.'
$content = $content -replace "A'(?=[!:\`'])", 'A.'

$content = $content -replace '\bAY\b', 'A.'
$content = $content -replace '\bBY\b', 'B.'
$content = $content -replace '\bCY\b', 'C.'
$content = $content -replace '\bDY\b', 'D.'

# Remove corrupted marker characters that come after option letters
$content = $content -replace 'A\.t\b', 'A.'
$content = $content -replace 'B\.t\b', 'B.'
$content = $content -replace "A\.\s+t\b", 'A.'

# Fix markers with dashes
$content = $content -replace 'A-(?=\s)', 'A.'
$content = $content -replace 'B-(?=\s)', 'B.'
$content = $content -replace 'C-(?=\s)', 'C.'
$content = $content -replace 'D-(?=\s)', 'D.'

# Fix spaces in markers (like "A ." should be "A.")
$content = $content -replace '\bA\s+\.', 'A.'
$content = $content -replace '\bB\s+\.', 'B.'
$content = $content -replace '\bC\s+\.', 'C.'
$content = $content -replace '\bD\s+\.', 'D.'

# Step 2: Remove numeric option markers that are clearly wrong (lines like "   2. text" or "   3. text" in option position)
$lines = $content -split "`n"
$output = @()
$i = 0

while ($i -lt $lines.Count) {
    $line = $lines[$i]
    
    # Skip blank lines and separators
    if ($line -match '^\s*$' -or $line -match '^_{3,}') {
        $i++
        continue
    }
    
    # Check for question header (starts with digit followed by period and text)
    if ($line -match '^\d+\.\s+\w') {
        $output += $line
        $i++
        
        # Collect options for this question
        $optionCount = 0
        while ($i -lt $lines.Count -and $optionCount -lt 5) {
            $testLine = $lines[$i]
            
            # Stop if next question
            if ($testLine -match '^\d+\.\s+\w') {
                break
            }
            
            # Skip blank/separator
            if ($testLine -match '^\s*$' -or $testLine -match '^_{3,}') {
                $i++
                continue
            }
            
            # Check if this is a valid option line
            $trimmed = $testLine.Trim()
            
            # Valid option line starts with A., B., C., or D. (but not numeric like 2. 3. 4.)
            if ($trimmed -match '^[A-D]\.' -and $trimmed -notmatch '^\d+\.') {
                $output += $testLine
                $optionCount++
            }
            # Also skip lines that JUST have numeric markers with nothing else
            elseif ($trimmed -match '^\d+\.\s+[a-z]' -or $trimmed -match '^\*\s+') {
                # Skip these - they're malformed options
            }
            # Keep other content (question continuation lines)
            elseif ($trimmed -notmatch '^\d+\s*\.' -and $trimmed.Length -gt 0) {
                # This might be a question continuation
                if ($trimmed -notmatch '^[a-z]' -and -not ($trimmed -match '^[A-D]\.')) {
                    $output += $testLine
                }
            }
            
            $i++
        }
    } else {
        $i++
    }
}

# Write the cleaned content
$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8

Write-Host "Aggressive clean complete. Output: $($output.Count) lines"
