# UltimateFinalCleanup.ps1
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# Step 1: Fix any remaining corrupted markers with apostrophes/quotes
$content = $content -replace "([A-D])' ", '$1. '
$content = $content -replace "([A-D])'!", '$1.'
$content = $content -replace "([A-D])' ", '$1. '

# Step 2: Replace remaining numeric prefixes in option lines
# Pattern: lines that start with "3. something" where 3 should be C, etc
$lines = $content -split "`n"
$output = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    # If starts with 3. (and not a question), should be C or A option
    if ($line -match '^\s*3\.\s+' -and $line -notmatch '^\d+\.\s+') {
        # Replace with C.
        $line = $line -replace '^\s*3\.\s+', 'C. '
    }
    # If starts with 4. (and not a question), should be D or B option
    elseif ($line -match '^\s*4\.\s+' -and $line -notmatch '^\d+\.\s') {
        $line = $line -replace '^\s*4\.\s+', 'D. '
    }
    # If starts with 2. in option context
    elseif ($line -match '^\s*2\.\s+' -and $line -notmatch '^\d+\.\s+') {
        # Only replace if it's clearly an option (not a question header)
        if (-not ($line -match '^\d\.\s+\w.*:$')) {
            $line = $line -replace '^\s*2\.\s+', 'B. '
        }
    }
    
    $output += $line
}

$output -join "`n" | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Ultimate final cleanup complete"
