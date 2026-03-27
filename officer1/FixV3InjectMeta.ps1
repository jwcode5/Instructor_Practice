$v3 = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v3.html'
$content = Get-Content $v3 -Raw

$answerMap = @{}
[regex]::Matches($content, 'q(\d+)\s*:\s*"([a-d])"') | ForEach-Object {
    $answerMap[[int]$_.Groups[1].Value] = $_.Groups[2].Value
}

if ($answerMap.Count -lt 100) {
    throw "Could not parse full answerKey. Found $($answerMap.Count) entries."
}

$pattern = '(?s)(<div class="question" id="q(\d+)">.*?<div class="options">\s*)(?!<div class="question-meta")'

$content = [regex]::Replace($content, $pattern, {
    param($m)
    $qNum = [int]$m.Groups[2].Value
    $ans = $answerMap[$qNum]
    if (-not $ans) { $ans = 'a' }

    $meta = "`r`n`t`t<div class=""question-meta"" data-section=""TBD"" data-page=""--"" data-correct=""$ans"" style=""display: none;""></div>"
    return $m.Groups[1].Value + $meta
})

Set-Content -Path $v3 -Value $content -Encoding UTF8
Write-Host 'Injected missing metadata blocks into v3.'
