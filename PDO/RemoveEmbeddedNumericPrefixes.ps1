# RemoveEmbeddedNumericPrefixes.ps1
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$lines = @(Get-Content $filePath -Encoding UTF8)
$output = @()

$i = 0
while ($i -lt $lines.Count) {
    $line = $lines[$i]
    
    # Check if this is a question header
    if ($line -match '^\d+\.\s+\w') {
        $output += $line
        $i++
        
        # Collect options for this question
        $qNum = 1
        while ($i -lt $lines.Count) {
            $testLine = $lines[$i]
            
            # Stop at next question
            if ($testLine -match '^\d+\.\s+\w') {
                break
            }
            
            # Skip blank lines
            if ($testLine -match '^\s*$') {
                $output += $testLine
                $i++
                continue
            }
            
            # Process option lines
            # If starts with spaces then number, convert to proper option marker
            if ($testLine -match '^\s+(\d+)\.\s+') {
                # Extract the content after the number
                $match = [regex]::Match($testLine, '^\s+\d+\.\s+(.*)$')
                if ($match.Success) {
                    $content = $match.Groups[1].Value
                    # Replace with A/B/C/D based on current option number
                    $labels = @('A.', 'B.', 'C.', 'D.')
                    if ($qNum -le 4) {
                        $output += "$($labels[$qNum - 1]) $content"
                        $qNum++
                    } else {
                        $output += $testLine  # Keep as-is if we have more than 4 options
                    }
                } else {
                    $output += $testLine
                }
            } else {
                # Regular option or continuation line
                $output += $testLine
            }
            
            $i++
        }
    } else {
        $output += $line
        $i++
    }
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Removed embedded numeric prefixes"
