# FinalMarkerCleanup.ps1
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# Fix remaining corrupted markers
$content = $content -replace "C':", 'B.'        # C': -> B.
$content = $content -replace "B'!", 'B.'        # B'! -> B.
$content = $content -replace "B'!", 'B.'        # B'! -> B.
$content = $content -replace "C'`"", 'C.'       # C'" -> C.

# Fix various apostrophe/quote corruptions
$content = $content -replace "A'f\b", 'A.'
$content = $content -replace "B'I\b", 'B.'
$content = $content -replace "A'`\b", 'A.'
$content = $content -replace "C'`\b", 'C.'

# Remove any remaining garbage characters
$content = $content -replace '`', ''            # Remove backticks
$content = $content -replace '"', ''            # Remove stray quotes

# Fix standing alone lines without markers by trimming leading spaces
$lines = $content -split "`n"
$output = @()

foreach ($line in $lines) {
    # If line is just text without option marker, trim leading spaces
    # but only if it looks like option content (lowercase, doesn't start line like a question)
    if ($line -match '^\s+([a-z])' -and $line -notmatch '^\s+\d+\.') {
        # Check if it's definitely an orphaned option line (no marker)
        if ($line -notmatch '^[A-D]\.' -and $line.Trim().Length -gt 2) {
            $line = $line.Trim()
        }
    }
    
    $output += $line
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Final marker cleanup complete"
