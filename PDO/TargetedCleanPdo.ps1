# TargetedCleanPdo.ps1
$filePath = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt"
$lines = @(Get-Content $filePath -Encoding UTF8)
$output = @()

function NormalizeMarkers {
    param([string]$text)
    # Fix OCR variant markers
    $text = $text -replace '\bAY\b', 'A.'
    $text = $text -replace '\bBY\b', 'B.'
    $text = $text -replace '\bCY\b', 'C.'
    $text = $text -replace '\bDY\b', 'D.'
    return $text
}

function ExtractOptions {
    param([string]$line)
    
    # Example: "1. repair.        BY maintenance.        C. reliability.        D. trouble shooting."
    # Should become: A. repair, B. maintenance, C. reliability, D. trouble shooting
    
    $result = @()
    $normalized = NormalizeMarkers $line
    
    # Replace numeric markers with letter markers (1. → A., 2. → B., etc.) 
    # but only at the start of option-like sequences
    $normalized = $normalized -replace '^\s*1\.(\s+[a-z])', 'A.$1'
    $normalized = $normalized -replace '\s{2,}2\.(\s+[a-z])', '  B.$1'
    $normalized = $normalized -replace '\s{2,}3\.(\s+[a-z])', '  C.$1'
    $normalized = $normalized -replace '\s{2,}4\.(\s+[a-z])', '  D.$1'
    
    # Find all option markers and their positions
    $pattern = '[A-D]\.'
    $matches = [regex]::Matches($normalized, $pattern)
    
    if ($matches.Count -le 1) {
        # Not a multi-option line
        return @($line)
    }
    
    # Extract text for each option
    $optionTexts = @()
    for ($i = 0; $i -lt $matches.Count; $i++) {
        $startPos = $matches[$i].Index + 2  # After "A. " or "B. ", etc.
        
        # Find end position (start of next option or end of line)
        if ($i + 1 -lt $matches.Count) {
            $endPos = $matches[$i + 1].Index
        } else {
            $endPos = $normalized.Length
        }
        
        $optionText = $normalized.Substring($startPos, $endPos - $startPos).Trim()
        
        # Remove any remaining numeric prefix if present
        $optionText = $optionText -replace '^\d+\.\s*', ''
        
        $optionTexts += $optionText
    }
    
    # Reconstruct with proper A/B/C/D labels
    $labels = @('A.', 'B.', 'C.', 'D.')
    for ($i = 0; $i -lt $optionTexts.Count -and $i -lt 4; $i++) {
        $result += "$($labels[$i]) $($optionTexts[$i])"
    }
    
    return $result
}

# Process lines
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # Normalize markers first
    $normalized = NormalizeMarkers $line
    
    # Skip separators
    if ($normalized -match '^\s*$' -or $normalized -match '^_{3,}') {
        # Keep one blank line
        if ($output.Count -gt 0 -and $output[-1] -notmatch '^\s*$') {
            $output += ''
        }
        continue
    }
    
    # Check if line contains multiple options (has 2+ option markers)
    $optionMatches = [regex]::Matches($normalized, '[A-D]\.')
    if ($optionMatches.Count -ge 2) {
        # Multi-option line - split it
        $splitOptions = ExtractOptions $line
        foreach ($opt in $splitOptions) {
            $output += $opt
        }
    } else {
        # Single option or regular text
        if ($normalized -match '^[A-D]\.' -or $normalized -match '^\d+\.\s+[\w]') {
            $output += $normalized
        } else {
            # Regular question text
            $output += $normalized
        }
    }
}

# Clean up excess blank lines
$final = @()
for ($i = 0; $i -lt $output.Count; $i++) {
    $line = $output[$i]
    if ($line -match '^\s*$') {
        if ($i -eq 0 -or $i -eq $output.Count - 1) {
            continue  # Skip leading/trailing blanks
        }
        if ($final.Count -gt 0 -and $final[-1] -match '^\s*$') {
            continue  # Skip double blanks
        }
    }
    $final += $line
}

$final -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Targeted clean complete. Output: $($final.Count) lines"
