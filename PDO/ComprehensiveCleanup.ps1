# ComprehensiveCleanup.ps1 - Final polish for PDO test file
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# 1. Fix double periods
$content = $content -replace 'C\.\.', 'C.'
$content = $content -replace 'A\.\.', 'A.'
$content = $content -replace 'B\.\.', 'B.'
$content = $content -replace 'D\.\.', 'D.'

# 2. Fix artifact characters at line starts
$content = $content -replace '\*\s+D\.', 'D.'  # Remove leading asterisks
$content = $content -replace '\[Y', ''         # Remove [Y (common OCR artifact)
$content = $content -replace '\[\}', ''        # Remove [}

# 3. Strip leading whitespace from option lines
$lines = $content -split "`n"
$output = @()

foreach ($line in $lines) {
    # If line starts with whitespace followed by letter/option, trim it
    if ($line -match '^\s+([A-D]\.)') {
        $line = $line -replace '^\s+', ''
    }
    
    # If line is just whitespace with numeric prefix (OCR artifact), skip it
    if ($line -match '^\s+\d+\.\s+$') {
        continue
    }
    
    # If line is leading spaces followed by just a number and period at start of a question-like structure, clean it
    if ($line -match '^\s+(\d+)\.\s+([a-z])' -and -not ($line -match '^\d+\.\s+')) {
        # This is a misplaced numeric prefix - strip the leading number
        $line = $line -replace '^\s+\d+\.\s+', ''
    }
    
    $output += $line
}

# Rejoin and write
$content = $output -join "`n"

# Final pass: fix corrupted markers
$content = $content -replace 'c\.,\.\.', 'C.'

$content | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Comprehensive cleanup complete"
