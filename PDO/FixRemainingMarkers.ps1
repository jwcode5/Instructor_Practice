# FixRemainingMarkers.ps1
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# Fix B.' and A.'
$content = $content -replace "B\.' ", 'B. '
$content = $content -replace "A\.' ", 'A. '
$content = $content -replace "B\.'", 'B.'
$content = $content -replace "A\.'", 'A.'

# Handle lines with multiple options like "A. not suggest        B. recommend"
# Split these onto separate lines
$lines = $content -split "`n"
$output = @()

foreach ($line in $lines) {
    # Look for patterns like "A. ... [2+ spaces] B. ..." indicating multi-option line
    if ($line -match '^[A-D]\.' -and $line -match '\s{2,}[A-D]\.') {
        # Split by multiple spaces before option markers
        $parts = $line -split '(?=\s{2,}[A-D]\.)'
        
        foreach ($part in $parts) {
            $part = $part.Trim()
            if ($part.Length -gt 0) {
                # If part doesn't start with option marker but has content, add one
                if ($part -notmatch '^[A-D]\.') {
                    # Find next option marker that might have been trimmed
                    if ($part -match '^[A-D]\.\s') {
                        $output += $part
                    }
                } else {
                    $output += $part
                }
            }
        }
    } else {
        $output += $line
    }
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Fixed remaining markers"
