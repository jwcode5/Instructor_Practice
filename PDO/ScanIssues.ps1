# ScanIssues.ps1
$file = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = @(Get-Content $file)

Write-Host "Total lines: $($content.Count)"
Write-Host ""
Write-Host "Double periods (C.., etc):"
$matches = $content | Select-String '\.\.' 
if ($matches) { $matches | Select-Object -First 5 }

Write-Host ""
Write-Host "Lines starting with spaces then numbers:"
$matches = $content | Select-String '^\s+\d+\.' 
if ($matches) { $matches | Select-Object -First 5 }

Write-Host ""
Write-Host "Artifact characters:"
$matches = $content | Select-String '^[\[\*\|]' 
if ($matches) { $matches | Select-Object -First 5 }

Write-Host ""
Write-Host "Lines with embedded leading numbers in options:"
$matches = $content | Select-String '^\s+\d+\.\s+[A-D]\.' 
if ($matches) { $matches | Select-Object -First 5 }
