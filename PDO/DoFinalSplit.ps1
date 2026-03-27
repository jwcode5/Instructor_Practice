# DoFinalSplit.ps1 - Handle remaining multi-option lines and apostrophe markers
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# Replace all remaining apostrophe corruption variants
$content = $content -replace "D'\s+", 'D. '
$content = $content -replace "C'\s+", 'C. '
$content = $content -replace "B'\s+", 'B. '
$content = $content -replace "A'\s+", 'A. '

# Handle remaining multi-option lines like "C. sulfuric        D. hydrogen"
$lines = $content -split "`n"
$output = @()

foreach ($line in $lines) {
    # Check for multi-option lines
    $matches = [regex]::Matches($line, '[A-D]\.')
    
    if ($matches.Count -ge 2) {
        # Split multi-option line
        $parts = $line -split '(?=[A-D]\. )'
        
        foreach ($part in $parts) {
            $trimmed = $part.Trim()
            if ($trimmed.Length -gt 2 -and $trimmed -match '^[A-D]\.') {
                $output += $trimmed
            }
        }
    } else {
        $output += $line
    }
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Final split and apostrophe fix complete"
