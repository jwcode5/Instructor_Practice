# FindRemainingIssues.ps1
$file = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt'
$content = @(Get-Content $file)

Write-Host "Lines with B.' or similar corruption:"
$content | Select-String "B\.' " | Select-Object -First 3

Write-Host ""
Write-Host "Lines starting with lowercase letter (no marker):"
$content | Select-String '^[a-z]' | Select-Object -First 5

Write-Host ""
Write-Host "Checking total issues in 10. range:"
for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^10\.' -or ($i -gt 0 -and $content[$i-1] -match '^10\.')) {
        Write-Host $content[$i]
        if ($i -lt 10) { break }
    }
}
