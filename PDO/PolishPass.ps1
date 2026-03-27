# PolishPass.ps1 - Final minor fixes
$filePath = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = Get-Content $filePath -Raw -Encoding UTF8

# Fix B.' -> B.
$content = $content -replace "B\.' ", 'B. '
$content = $content -replace "B\.'$", 'B.'

# Fix C."
$content = $content -replace 'C\." ', 'C. '

# Remove leading spaces before option markers
$lines = $content -split "`n"
$output = @()

foreach ($line in $lines) {
    # If line is just spaces followed by option marker, trim it
    if ($line -match '^\s+[A-D]\.' -and $line -notmatch '^\d+\.') {
        $line = $line -replace '^\s+', ''
    }
    
    $output += $line
}

$output -join "`n" | Out-File $filePath -Encoding UTF8
Write-Host "Polish pass complete"
