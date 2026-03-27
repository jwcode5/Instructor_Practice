# FinalNormalizePdo.ps1 - Final OCR marker cleanup
$filePath = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt"
$content = Get-Content $filePath -Raw -Encoding UTF8

# Final marker normalization - fix remaining OCR corruptions
$content = $content -replace '\bAot\b', 'A.'
$content = $content -replace '\bBot\b', 'B.'
$content = $content -replace '\bCot\b', 'C.'
$content = $content -replace '\bDot\b', 'D.'

$content = $content -replace '\bAi\b', 'A.'
$content = $content -replace '\bBi\b', 'B.'
$content = $content -replace '\bCi\b', 'C.'
$content = $content -replace '\bDi\b', 'D.'

$content = $content -replace '\bA\.\.\b', 'A.'
$content = $content -replace '\bB\.\.\b', 'B.'
$content = $content -replace '\bC\.\.\b', 'C.'
$content = $content -replace '\bD\.\.\b', 'D.'

# Fix spacing issues
$content = $content -replace '^\s+([A-D]\.)' , '$1'

# Remove leading numeric markers that shouldn't be there
$content = $content -replace '^\s+\d+\.\s+(?=[A-D]\.)', ''

# Fix Ct and Bt at line starts (common OCR error for C. and B.)
$content = $content -replace '^Ct\s+', 'C. '
$content = $content -replace '^Bt\s+', 'B. '
$content = $content -replace '^At\s+', 'A. '
$content = $content -replace '^Dt\s+', 'D. '

$content | Out-File -FilePath $filePath -Encoding UTF8
Write-Host "Final normalization complete"
